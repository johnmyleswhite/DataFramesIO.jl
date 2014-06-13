const DELIMS = convert(Vector{Uint8}, Base._default_delims)

function strip(v::Vector{Uint8}, l::Int = 1, r::Int = length(v))
    v[colon(stripbounds(v, l, r)...)]
end

function stripbounds(v::Vector{Uint8}, l::Int = 1, r::Int = length(v))
    for u in v
        if !(u in DELIMS)
            break
        end
        l += 1
    end
    if l < r
        @inbounds for r in r:-1:l
            if !(v[r] in DELIMS)
                break
            end
        end
    end
    return l, r
end

function readeol(io::IO)
    c = read(io, Uint8)
    if c == uint('\n')
        # continue
    elseif c == uint('\r')
        if eof(io)
            error("Expected eol character, got end of file")
        else
            c = read(io, Uint8)
            c == uint('\n') || error("Expected '\n' after '\r', got '$(char(c))' ($c)")
        end
    else
        error("Expected eol character, got '$(char(c))' ($c)")
    end
    nothing
end

function readthrougheol(io::IO)
    while !eof(io)
        c = read(io, Uint8)
        if c == uint('\n')
            break
        end
    end
end


function fwf2df(path::String, args...; kwargs...)
    open(io -> fwf2df(io, args...; kwargs...), path, "r")
end

for widths in [true, false]
    bounds = !widths
    @eval begin
        function fwf2df(io::IO,
                        eltypes::Vector{DataType},
                        $(widths ?
                            :(widths::Vector{Int}) :
                            :(bounds::Vector{(Int,Int)})
                        ),
                        names::Vector{Symbol} = DataFrames.gennames(length(eltypes));
                        nastrings::Vector{ASCIIString} = $(widths ?
                            :(map(w -> " "^w, widths)) :
                            :(map(b -> " "^(b[2] - b[1] + 1), bounds))
                        ),
                        strip::Bool = true,
                        skipstart::Int = 0)

            n = length(eltypes)

            $(if bounds
                quote
                    widths = map(t -> t[2] - t[1] + 1, bounds)
                    gaps = [bounds[i][1] - (i == 1 ? 0 : bounds[i - 1][2]) - 1 for i in 1:n]
                end
            end)

            if !all(t -> t <: Union(ASCIIString, UTF8String, Integer, FloatingPoint), eltypes)
                throw(ArgumentError("Types must be string, integer, or floating point types"))
            end

            if length(widths) != n || length(names) != n
                throw(ArgumentError("All vector arguments must have the same length"))
            end

            i, clen = 0, 1
            cols = Any[DataArray(eltypes[j], clen) for j=1:n]
            buffers = map((t, w) -> buf(t, w), eltypes, widths)

            for _ in 1:skipstart
                readthrougheol(io)
            end

            while !eof(io)
                i += 1
                if i > clen
                    clen *= 2
                    for col in cols
                        resize!(col, clen)
                    end
                end

                @inbounds for j in 1:n
                    $(if bounds
                        :(for _ in 1:gaps[j]; read(io, Char); end)
                    end)

                    cols[j][i]  = readentry!(io, eltypes[j], widths[j], nastrings[j].data, buffers[j])
                end

                $(widths ? :(readeol(io)) : :(readthrougheol(io)))
            end

            close(io)

            for col in cols
                resize!(col, i)
            end

            DataFrame(cols, names)
        end
    end
end


buf(::Type{UTF8String}, w::Int) = Array(Uint8, 6w)
buf(::Type, w::Int) = Array(Uint8, w)


function readentry!(io::IO, ::Type{ASCIIString}, width::Int, na::Vector{Uint8}, buffer::Vector{Uint8})
    read!(io, buffer)
    buffer == na ? NA : ASCIIString(strip(buffer, 1, width))
end

function readentry!(io::IO, ::Type{UTF8String}, width::Int, na::Vector{Uint8}, buffer::Vector{Uint8})
    i = 0
    namatch = true
    for j in 1:width
        i += 1
        c = read(io, Uint8)
        namatch && (i > length(na) || c != na[i]) && (namatch = false)
        buffer[i] = c
        if c >= 0x80
            # mimic utf8.next function
            trailing = Base.utf8_trailing[c+1]
            for k = 1:trailing
                i += 1
                c = read(io, Uint8)
                buffer[i] = c
                namatch && (i > length(na) || c != na[i]) && (namatch = false)
            end
        end
    end

    namatch ? NA : UTF8String(strip(buffer, 1, i))
end

function readentry!{T <: Signed}(io::IO, ::Type{T}, width::Int, na::Vector{Uint8}, buffer::Vector{Uint8})
    read!(io, buffer)
    buffer == na && return NA

    l, r = stripbounds(buffer, 1, width)

    c = buffer[l]
    negative = c == uint8('-')
    if c == uint8('+') || c == uint8('-')
        l += 1
    end

    l > r && error("Empty (but non-NA) entry in integer column")

    entry = 0
    place = 1
    for i in r:-1:l
        c = buffer[i]
        if uint8('0') <= c <= uint8('9')
            entry += (c - uint8('0')) * place
            place *= 10
        else
            error("Invalid character '$(char(c))' ($c) in integer column")
        end
    end

    return convert(T, negative ? -entry : entry)
end

function readentry!{T <: Unsigned}(io::IO, ::Type{T}, width::Int, na::Vector{Uint8}, buffer::Vector{Uint8})
    read!(io, buffer)
    buffer == na && return NA

    l, r = stripbounds(buffer, 1, width)

    if buffer[l] == uint8('+')
        l += 1
    end

    l > r && error("Empty (but non-NA) entry in integer column")

    entry = 0
    place = 1
    for i in r:-1:l
        c = buffer[i]
        if uint8('0') <= c <= uint8('9')
            entry += (c - uint8('0')) * place
            place *= 10
        else
            error("Invalid character '$(char(c))' ($c) in integer column")
        end
    end

    return convert(T, entry)
end

let out = Array(Float64, 1)
    global readentry!
    function readentry!{T <: FloatingPoint}(io::IO, ::Type{T}, width::Int, na::Vector{Uint8}, buffer::Vector{Uint8})
        read!(io, buffer)
        buffer == na && return NA

        ccall(:jl_strtod,
              Int32,
              (Ptr{Uint8}, Ptr{Float64}),
              buffer,
              out) == 0 || error("Non-number '$(bytestring(buffer))' in float column")

        return convert(T, out[1])
    end
end
