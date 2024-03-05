include("Ternary.jl")
using .Ternary

function printMat(s::String, matrix::AbstractMatrix)
    println("=== $s ===")
    # Determine the width needed for each column
    col_widths = [maximum([length(string(matrix[i, j])[end]) for i in 1:size(matrix, 1)]) for j in 1:size(matrix, 2)]
    
    println("-" ^ (sum(col_widths) + 3 * size(matrix, 2) + 1))
    for i in 1:size(matrix, 1)
        print("|")
        for j in 1:size(matrix, 2)
            str = string(matrix[i, j])[end]
            fmt_str = " $(str) "
            padding = col_widths[j] - length(str)
            print(" " ^ (padding ÷ 2), fmt_str, " " ^ (padding - padding ÷ 2), "|")
        end
        println()
        println("-" ^ (sum(col_widths) + 3 * size(matrix, 2) + 1))
    end
    println()
end

n4 = Tryte("--")
n3 = Tryte("-0")
n2 = Tryte("-+")
n1 = Tryte("-")
z = Tryte("0")
p1 = Tryte("+")
p2 = Tryte("+-")
p3 = Tryte("+0")
p4 = Tryte("++")

F = Tryte("-")
U = Tryte("0")
T = Tryte("+")

function create_table(op)
    return [
        op(F,F) op(F,U) op(F,T);
        op(U,F) op(U,U) op(U,T);
        op(T,F) op(T,U) op(T,T);
    ]
end

function compare(op, truth)
    Int.(create_table(op) .== truth)
end

NOTt = [T, U, F]
printMat("NOT", reshape(Int.(map(~, [F, U, T]) .== NOTt), (3,1)))

ANDt = [
    F F F;
    F U U;
    F U T;
]
printMat("AND", compare(&, ANDt))

NANDt = [
    T T T;
    T U U;
    T U F;
]
printMat("NAND", compare(⊼, NANDt))

ORt = [
    F U T;
    U U T;
    T T T;
]
printMat("OR", compare(|, ORt))

NORt = [
    T U F;
    U U F;
    F F F;
]
printMat("NOR", compare(⊽, NORt))

XORt = [
    F U T;
    U U U;
    T U F;
] 
printMat("XOR", compare(⊻, XORt))

XNORt = [
    T U F;
    U U U;
    F U T;
] 
printMat("XNOR", compare(⩢, XNORt))

CARRYt = [
    F U U;
    U U U;
    U U T;
]
printMat("CARRY", compare(carry, CARRYt))

PSUMt = [
    T F U;
    F U T;
    U T F;
]
printMat("PSUM", compare(psum, PSUMt))

trytes = [n4, n3, n2, n1, z, p1, p2, p3, p4]
println("Testing shift operator")
for t in trytes
    println("OG:", t)
    println("LS:", t << 1)
    println("RS:", t >> 1)
    println()
    println("OG:", bitstring(t))
    println("LS:", bitstring(t << 1))
    println("RS:", bitstring(t >> 1))
    println()
    println()
end

for x in trytes
    for y in trytes
        println("$(Int(x)) + $(Int(y)) = $(Int(x+y)) : $(Int(x) + Int(y) == Int(x+y))")
    end
end
big = Tryte("++++++++++++++++++++++++++++++++++++++++++")
small = Tryte("------------------------------------------")
println(big + p1 == small)
println(small - p1 == big)

println("Test addition")
trytes = [Tryte(i) for i in -1000:1000]
for x in trytes
    for y in trytes
        if !(Int(x) + Int(y) == Int(x+y))
            println("?")
        end
    end
end

println("Test subtraction")
for x in trytes
    for y in trytes
        if !(Int(x) - Int(y) == Int(x-y))
            println("?")
        end
    end
end

println("Test multiplication")
for x in trytes
    for y in trytes
        if !(Int(x) * Int(y) == Int(x*y))
            println("?")
        end
    end
end






