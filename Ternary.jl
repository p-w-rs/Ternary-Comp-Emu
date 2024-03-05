module Ternary

using Base

export Tryte, ⩢, carry, psum

# Helper Functions and Definitions
const F::UInt128 = UInt128(0b00)
const U::UInt128 = UInt128(0b01)
const Ū::UInt128 = UInt128(0b10)
const T::UInt128 = UInt128(0b11)
const TRYTE_SIZE::Int64 = 42
const TRYBITS::Int64 = TRYTE_SIZE*2
const BINBITS::Int64 = 128
const MASK::UInt128 = 0x0000_0000_000F_FFFF_FFFF_FFFF_FFFF_FFFF # Mask to clear the first n (BINBITS - TRYBITS) bits
const ZERO::UInt128 = 0x0000_0000_0005_5555_5555_5555_5555_5555 # Zero mask in ternary
const ZERŌ::UInt128 = 0x0000_0000_000A_AAAA_AAAA_AAAA_AAAA_AAAA # Zero inverse mask in ternary
const MASK01::UInt128 = 0x5555_5555_5555_5555_5555_5555_5555_5555 # Mask of all 0b010101...01
const MASK10::UInt128 = 0xAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA # Mask of all 0b101010...10
const MASK11::UInt128 = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF # Mask of all 0b111111...11
const set_mask(x::UInt128, i::Int64)::UInt128 = x << (2 * (i-1)) # Set the mask for a given trit
const get_mask(i::Int64)::UInt128 = T << (2 * (i-1))
const ensure_mask(x::UInt128)::UInt128 = x & MASK # Ensure the value is within 36 bits

# Tryte Type
struct Tryte
    data::UInt128
    dinv::UInt128
end

# Constructors
function Tryte(s::String)::Tryte
    length(s) > TRYTE_SIZE && throw(ArgumentError("Input string must not exceed a length of 18"))
    data = UInt128(0)
    dinv = UInt128(0)
    start = 0
    for (i, ch) in enumerate(reverse(s))
        if ch == '+'
            data |= set_mask(T, i)
            dinv |= set_mask(T, i)
        elseif ch == '0'
            data |= set_mask(U, i)
            dinv |= set_mask(Ū, i)
        elseif ch == '-' # This branch is actually pointless but it's nice for completeness
            data |= set_mask(F, i)
            dinv |= set_mask(F, i)
        else 
            throw(ArgumentError("Invalid character in string"))
        end
        start = i+1
    end
    for i in start:TRYTE_SIZE
        data |= set_mask(U, i)
        dinv |= set_mask(Ū, i)
    end
    return Tryte(ensure_mask(data), ensure_mask(dinv))
end

function Tryte(n::Int)::Tryte
    s = ""
    value = n
    for _ in 1:TRYTE_SIZE
        value == 0 && break
        rem, value = value % 3, value ÷ 3
        if rem == 2
            rem = -1
            value += 1
        elseif rem == -2
            rem = 1
            value -= 1
        end

        if rem == 1
            s = '+' * s
        elseif rem == -1
            s = '-' * s
        else
            s = '0' * s
        end
    end
    return Tryte(s)
end

# IO Operators
function Base.show(io::IO, t::Tryte)::Nothing
    chars = ['-', '0', '0', '+']
    for i in reverse(0:TRYTE_SIZE-1)
        mask = get_mask(i+1)
        trit_val = (t.data & mask) >> (i*2)
        print(io, chars[trit_val+1])
    end
end

function Base.bitstring(t::Tryte)::String
    return bitstring(t.data)
end

function Base.Int(t::Tryte)::Int64
    value = 0
    for i in 0:TRYTE_SIZE-1
        mask = get_mask(i+1)
        trit_val = (t.data & mask) >> (i*2)
        if trit_val == 0
            value += -(3^i)
        elseif trit_val == 3
            value += 3^i
        end
    end
    return value
end

#== Tritwise Operators ==#
# not
Base.:~(t::Tryte)::Tryte = Tryte(ensure_mask(~t.dinv), ensure_mask(~t.data))
# and
Base.:&(x::Tryte, y::Tryte)::Tryte = Tryte(x.data & y.data, x.dinv & y.dinv)
# or
Base.:|(x::Tryte, y::Tryte)::Tryte = Tryte(x.data | y.data, x.dinv | y.dinv)
# nand
Base.:⊼(x::Tryte, y::Tryte)::Tryte = ~(x & y)
# nor
Base.:⊽(x::Tryte, y::Tryte)::Tryte = ~(x | y)
# xor
Base.:⊻(x::Tryte, y::Tryte)::Tryte = (x & y) ⊽ (x ⊽ y)
# xnor
⩢(x::Tryte, y::Tryte)::Tryte = ~(x ⊻ y)
# Shift right one trit
function Base.:>>(x::Tryte, i::Int64)::Tryte
    shift_amount = i * 2
    mask_shift_amount = TRYBITS - shift_amount
    shifted_data = ensure_mask((x.data >> shift_amount) | (MASK01 << mask_shift_amount))
    shifted_dinv = ensure_mask((x.dinv >> shift_amount) | (MASK10 << mask_shift_amount))
    return Tryte(shifted_data, shifted_dinv)
end
# shift left one trit
function Base.:<<(x::Tryte, i::Int64)::Tryte
    shift_amount = i * 2
    mask_shift_amount = BINBITS - shift_amount
    shifted_data = ensure_mask((x.data << shift_amount) | (MASK01 >> mask_shift_amount))
    shifted_dinv = ensure_mask((x.dinv << shift_amount) | (MASK10 >> mask_shift_amount))
    return Tryte(shifted_data, shifted_dinv)
end

# Function that computes carry of the partial sum of x and y
function carry(x::Tryte, y::Tryte)::Tryte
    #=Tryte(
        (x.data & y.data) | ((x.data & MASK01) | (y.data & MASK01)),
        (x.dinv & y.dinv) | ((x.dinv & MASK10) | (y.dinv & MASK10))
    )=#
    Tryte(
        ((x.data ⊻ MASK01) & (y.data ⊻ MASK01)) ⊻ MASK01,
        ((x.dinv ⊻ MASK10) & (y.dinv ⊻ MASK10)) ⊻ MASK10
    )
end

# Function that compute the partial sum of x and y
function psum(x::Tryte, y::Tryte)::Tryte
    c = ~carry(x, y)

    a, ā = ensure_mask(~(x.data ⊻ y.data)), ensure_mask(~(x.dinv ⊻ y.dinv))
    b, b̄ = (x.data ⊻ y.data), (x.dinv ⊻ y.dinv)
    
    Tryte(
        c.data ⊻ (ā & b),
        c.dinv ⊻ (a & b̄)
    )
end

#== Arithmetic Operators ==#
const Tryte1̄::Tryte = Tryte("-")
const Tryte0::Tryte = Tryte("0")
const Tryte1::Tryte = Tryte("+")
const TryteMin::Tryte = Tryte("------------------------------------------")
const TryteMax::Tryte = Tryte("++++++++++++++++++++++++++++++++++++++++++")
const TryteE::Tryte = Tryte("-----------------------------------------+")
const TryteC::Tryte = Tryte("00000000000000000000000000000000000000000-")

Base.:(==)(x::Tryte, y::Tryte)::Bool = (x.data == y.data) && (x.dinv == y.dinv)
Base.:<(x::Tryte, y::Tryte)::Bool = Int(x) < Int(y)
Base.:>(x::Tryte, y::Tryte)::Bool = Int(x) > Int(y)
Base.:+(x::Tryte)::Tryte = x # Unary plus
Base.:-(x::Tryte)::Tryte = ~x # Unary minus

function Base.:+(x::Tryte, y::Tryte)::Tryte
    s, c = psum(x, y), carry(x, y)
    while (c.data != ZERO) && (c.dinv != ZERŌ)
        s, c = psum(s, c << 1), carry(s, c << 1)
    end
    return s
end
Base.:-(x::Tryte, y::Tryte)::Tryte = x + (-y)

function Base.:*(x::Tryte, _y::Tryte)::Tryte
    result = Tryte0
    if x != Tryte0 && _y != Tryte0
        y = _y
        for i in 0:TRYTE_SIZE-1
            y == Tryte0 && break
            yt = (y & TryteE) | TryteC
            y >>= 1
            if yt == Tryte1
                result += x << i
            elseif yt == Tryte1̄
                result -= x << i
            end
        end
    end
    return result
end

function Base.div(dividend::Tryte, divisor::Tryte)::Tuple{Tryte, Tryte}
    divisor == Tryte0 && return Tryte0, dividend
    divisor == Tryte1 && return dividend, Tryte0
    divisor == Tryte1̄ && return -dividend, Tryte0

    quotient = Tryte0
    remainder = dividend
    while remainder > divisor
        remainder -= divisor
        quotient += Tryte1
    end
    return quotient, remainder
end
Base.:/(x::Tryte, y::Tryte)::Tryte = div(x, y)[1]
Base.:%(x::Tryte, y::Tryte)::Tryte = div(x, y)[2]
Base.:\(x::Tryte, y::Tryte)::Tryte = div(y, x)[1]

function Base.:^(x::Tryte, n::Tryte)::Tryte
    # Your implementation for raises x to the yth power here
end

end
