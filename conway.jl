# implement conways Game of Life in Julia


function evolve(N::Int,grid,grid1::BitArray)
  for x = 1:N; for y = 1:N
       n = 0      
       for dx = -1:1; for dy = -1:1
           #x1 = (x + dx + N) % N + 1   # periodic boundaries
           #y1 = (y + dy + N) % N + 1
           x1 = x + dx 
           if x1 > N 
		x1 -= N  
           elseif x1 < 1 
		x1 += N 
	   end 
           y1 = y + dy 
           if y1 > N 
		y1 -= N 
           elseif y1 < 1
		 y1 += N 
	   end
           if grid[x1,y1]; n += 1; end
       end end
       if grid[x,y]; n -= 1; end
       grid1[x,y] = (n == 3 || (n == 2 && grid[x,y])) 
  end end
end


function iterate_grid(N::Int,iter::Int)
  grid = rand(N,N) .< 0.1
#  grid1 = Array(Bool,(N,N))
  grid1 = BitArray(Bool,(N,N))
  println(count(grid))
  for i=1:iter
    evolve(N,grid,grid1)
    #(grid,grid1) = (grid1,grid)
  end
  println(count(grid))
end

# main
println("We'll get it going ..")
@time iterate_grid(500,10)


