
function evolve(N::Int)
  x = 0::Int
  for i = 1:N
      #x = x + 1 
      #x = succ(x)
      x = scc(x)
  end
  x
end

scc(x::Int) = x + 1

function succ(x::Int)
  x + 1
  #x1::Int = x + 1
end



# main
println("We'll get going ..")
@time println(evolve(1000000000))


