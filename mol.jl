module Mol
# implement Model of Life in Julia
# Artificial Life simulator
# evolvable Langton Ants on Game of Life

require("Tk")
using Tk
using Cairo

# type Dir
# end

const dE_Move = 0.1   # energy cost for a movement

type Ant
  posx::Int
  posy::Int
  heading::Int    # 0..3  0 = right
  energy::Float32
  food::Bool

  function Ant(x,y,h,e,f)
    new(x,y,h,e,f)
  end
end

OptionAnt = Union(Nothing, Ant)

type Chart
  nx    ::Int
  ny    ::Int
  grid  ::Array{Bool,2}
  grid1 ::Array{Bool,2}
  agrid ::Array{OptionAnt,2}
  time  ::Int
  nAnts ::Int
  
  function Chart(ny,nx,x)
    #gridBit = rand(ny,nx) .< 0.1 ## this creates a bitarray!!
    #grid = convert(Array{Bool,2},gridBit)
    grid::Array{Bool,2} = rand(ny,nx) .< 0.1
    grid1 = Array(Bool,(ny,nx))
    agrid = Array(OptionAnt,(ny,nx))
    for i = 1 : ny; for j = 1:nx
      agrid[i,j] = nothing
    end end  
    new(nx,ny,grid,grid1,agrid,0,0)
  end
end


function wrap(x::Int,xmax::Int)
  if (x > xmax) 
    x -= xmax
  elseif (x < 1)    
    x += xmax; 
  end
  x
end

function neighbor(x,y::Int, nx,ny::Int, dir::Int)
# find grid coordinates of direct neighbor in direction dir
  if dir == 0      # go one step to the right
    x1 = wrap(x+1, nx)
    y1 = y
  elseif dir == 1  # go one step up
    x1 = x
    y1 = wrap(y-1, ny)
  elseif dir == 2
    x1 = wrap(x-1, nx)
    y1 = y
  elseif dir == 3
    x1 = x
    y1 = wrap(y+1, ny)
  end
  x1, y1
end

function stepGol(c)
   for x = 1:c.nx; for y = 1:c.ny
       n = 0::Int      
       for dx = -1:1; for dy = -1:1
           x1 = wrap(x+dx,c.nx)
           y1 = wrap(y+dy,c.ny)
           if c.grid[y1,x1]; n += 1; end
       end end
       if c.grid[y,x]; n -= 1; end
       c.grid1[y,x] = (n == 3 || (n == 2 && c.grid[y,x])) 
  end end
  (c.grid,c.grid1) = (c.grid1,c.grid)
end


function createAnts(p::Chart, nAnts)
  ants = Array(Ant,nAnts)
  for i=1:nAnts
    x = rand(1:p.nx)
    y = rand(1:p.ny)
# here we should check first that the grid position is empty
# ...........
    ant = Ant(x,y,1,10.0,false)
    ants[i] = ant
    p.agrid[y,x] = ant
  end
  p.nAnts = nAnts
  ants
end


function move(ant::Ant, p::Chart)
  x, y = neighbor(ant.posx,ant.posy,p.nx,p.ny,ant.heading)
  if !p.grid[y,x]
    p.agrid[ant.posy, ant.posx] = nothing
    p.agrid[y,x] = ant
    ant.posx = x
    ant.posy = y
    ant.energy -= dE_Move
    return true
  else
    return false
  end
end

function turnLeft(ant::Ant)
  ant.heading = mod(ant.heading-1,4)
end

function turnRight(ant::Ant)
  ant.heading = mod(ant.heading+1,4)
end

function seed(a::Ant, p::Chart)  # place a food item on GOL-grid
  if !p.grid[a.posy,a.posx]
    p.grid[a.posy,a.posx] = true
    a.energy -= 1.0
  end
end

function reap(a::Ant, p::Chart)  # take a food item from GOL-grid
  if p.grid[a.posy,a.posx]
    p.grid[a.posy,a.posx] = false
    a.energy += 1.0
  end
end

function die(a::Ant, p::Chart, ants)
  p.nAnts -= 1
  p.agrid[a.posy,a.posx] = nothing
  ind = findfirst(ants, a) # remove ant from list
  delete!(ants,ind)
end

function bear(a::Ant, p::Chart, ants, energy)
  x = a.posx
  y = a.posy
  deltaE = a.energy - energy
  # try to move the ant one step ..
  if deltaE > 0.0 && move(a,p)  
    #x, y = neighbor(a.posx,a.posy,p.nx,p.ny,a.heading)
    a.energy = deltaE
    #  .. and create offspring at the old position
    dir = rand(1:4)  # new heading is random 
    newAnt = Ant(x,y,1,10.0,energy) 
    push!(ants,newAnt)
    p.agrid[y,x] = newAnt
    p.nAnts +=1
    return true
  else
    return false
  end
end

function draw(p,ants,dx,cr,c)
# draw on the srceen
  # img = convert(Array{Uint32,2},grid) .* 0x00ffffff;
  # set_source_surface(cr, CairoRGBSurface(img), 0, 0)
  # paint(cr)

  for x = 1:p.nx; for y = 1:p.ny   # draw the grid
    if p.grid[y,x]
      #set_source_rgb(cr, 0, 0, 0.85)  # blue
      set_source_rgb(cr, 1, 1, 1)  # life cells in white
    else
      set_source_rgb(cr, 0, 0, 0)     # background in black
    end
    x1 = (x-1)*dx + 1
    y1 = (y-1)*dx + 1
    rectangle(cr,x1,y1,dx,dx)  # plots starting from top left corner
    fill(cr)
  end end

  for ant = ants             # draw ants
    x1 = (ant.posx-1)*dx + 1
    y1 = (ant.posy-1)*dx + 1
    if p.grid[ant.posy,ant.posx]
      set_source_rgb(cr, 0, 1, 0)  # green
    else
      set_source_rgb(cr, 1, 0, 0)  # green
    end
    rectangle(cr,x1,y1,dx,dx)  # plots starting from top left corner
    fill(cr)
  end

  reveal(c)

end


function runMol()
# main function to start the whole thing

  ny = 100   # size of board
  nx = 200
  sqWidth=4  # width of square on screen
  
  w = Window("Model of Life", nx*sqWidth, ny*sqWidth)
  c = Canvas(w)
  pack(c)
  cr = cairo_context(c)
  
  chart = Chart(ny,nx,0.1)
  ants = createAnts(chart,4)
  println(length(ants))
  println(ants[1])

  #delete!(ants,2)
  #ant = Ant(10,20,1,10.0,false)  


  c.mouse.button1press = (c,x,y)->(done=true)
  # c.mouse.button1press = function(c,x,y)
  #   done=true
  # end
  done = false
  println("We'll get going ..")
  println(countp(chart.grid))  
  #niter = 10000
  #for i=1:niter
  while !done
    stepGol(chart)
    for ant = ants
      move(ant,chart)
      if chart.grid[ant.posy,ant.posx]
        reap(ant,chart)
        turnLeft(ant)
      else
        seed(ant,chart)
        #turnRight(ant)
      end
      if ant.posx == 10
        die(ant,chart,ants)
      elseif ant.posx == 50
        println("new ant")
        bear(ant,chart,ants,-1.0)
      end
    end
   
    draw(chart,ants,sqWidth,cr,c)
    println(chart.nAnts)
    #sleep(1.0)

  end
end


# main
#@time iterate_grid(500,100)
@time runMol()

end  # end module
