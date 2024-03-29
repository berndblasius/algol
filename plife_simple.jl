function life_rule(old)
    m, n = size(old)
    new = similar(old, m-2, n-2)
    for j = 2:n-1
        for i = 2:m-1
            nc = +(old[i-1,j-1], old[i-1,j], old[i-1,j+1],
                   old[i  ,j-1],             old[i  ,j+1],
                   old[i+1,j-1], old[i+1,j], old[i+1,j+1])

            new[i-1,j-1] = (nc == 3 ? 1 :
                            nc == 2 ? old[i,j] :
                            0)
        end
    end
    new
end

function life_step(d)
    DArray(size(d),procs(d)) do I
        # fetch neighborhood - toroidal boundaries
        top   = mod(first(I[1])-2,size(d,1))+1
        bot   = mod( last(I[1])  ,size(d,1))+1
        left  = mod(first(I[2])-2,size(d,2))+1
        right = mod( last(I[2])  ,size(d,2))+1

        old = Array(Bool, length(I[1])+2, length(I[2])+2)
        @sync begin
            @async old[1      , 1      ] = d[top , left]   # left side
            @async old[2:end-1, 1      ] = d[I[1], left]
            @async old[end    , 1      ] = d[bot , left]
            @async old[1      , 2:end-1] = d[top , I[2]]
            @async old[2:end-1, 2:end-1] = d[I[1], I[2]]   # middle
            @async old[end    , 2:end-1] = d[bot , I[2]]
            @async old[1      , end    ] = d[top , right]  # right side
            @async old[2:end-1, end    ] = d[I[1], right]
            @async old[end    , end    ] = d[bot , right]
        end

        life_rule(old)
    end
end

function plife(m, n, niter)
    grid = DArray(I->randbool(map(length,I)), (m, n), [2:nprocs()])
	for i=1:niter
        grid = life_step(grid)
    end
end
