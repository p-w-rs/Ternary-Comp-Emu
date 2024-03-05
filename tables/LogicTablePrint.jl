using Luxor

include("Ternary.jl")
using .Ternary

function generate_matrix(F::UInt8, U::UInt8, T::UInt8, op::Function)
    inputs = [0b00, F, U, T]
    matrix = Matrix{UInt8}(undef, 4, 4)
    matrix[1, :] .= inputs
    matrix[:, 1] .= inputs
    for i in 2:4
        for j in 2:4
            if op == ⩢
                matrix[i, j] = ~(inputs[i] ⊻ inputs[j])
            else
                matrix[i, j] = op(inputs[i], inputs[j])
            end
        end
    end
    return matrix
end

function display_matrix(matrix, n::String)
    binary_matrix = [bitstring(matrix[i, j])[end-1:end] for i in 1:4, j in 1:4]
    binary_matrix[1, 1] = "$n"

    @png begin
        for i in 1:4
            for j in 1:4
                if i == 1 && j == 1
                    fontsize(10)
                    text(binary_matrix[i, j], Point(50*(i-3)+10, 50*(j-3)+28))
                elseif i > 1 && j > 1
                    fontsize(16)
                    rect(Point(50*(i-3), 50*(j-3)), 50, 50, action = :stroke)
                    text(binary_matrix[i, j], Point(50*(i-3)+16, 50*(j-3)+30))
                else
                    fontsize(20)
                    rect(Point(50*(i-3), 50*(j-3)), 50, 50, action = :stroke)
                    text(binary_matrix[i, j], Point(50*(i-3)+14, 50*(j-3)+32))
                end
            end
        end
    end 200 200 "tables/$n.png"
end

F = 0b00
U = 0b01
iU = 0b10
T = 0b11

s = Dict([
    (&) => "and",
    (|) => "or",
    (⊼) => "nand",
    (⊽) => "nor",
    (⊻) => "xor",
    (⩢) => "xnor"
])

PSUMt = [
    F F U T;
    F T F U;
    U F U T;
    T U T F;
]
display_matrix(PSUMt, "psum")

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F, U, T, op)
    display_matrix(matrix, "$(s[op])")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F&U, U&U, T&U, op)
    display_matrix(matrix, "$(s[op])&01")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F&iU, U&iU, T&iU, op)
    display_matrix(matrix, "$(s[op])&10")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F|U, U|U, T|U, op)
    display_matrix(matrix, "$(s[op])|01")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F|iU, U|iU, T|iU, op)
    display_matrix(matrix, "$(s[op])|10")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F⊻U, U⊻U, T⊻U, op)
    display_matrix(matrix, "$(s[op])^01")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F⊻iU, U⊻iU, T⊻iU, op)
    display_matrix(matrix, "$(s[op])^10")
end

for op in [&, |, ⊼, ⊽, ⊻, ⩢]
    matrix = generate_matrix(F⊻T, U⊻T, T⊻T, op)
    display_matrix(matrix, "$(s[op])^11")
end
