module Constructs
#=
A structure for a pseudo single production system based on SUT data.
The former is derived from the latter through application of a to-be-defined construct.

---

# usage as for example:

include("Constructs.jl")

### to get the final demand
itc = Constructs.ITC(<sut::SUT.structure>)
itc.y

# or

### to check if the stored Leontief inverse matches the calculated one
ctc = Constructs.CTC(<sut::SUT.structure>)
ctc.L == inv(I-ctc.A)
=#

    using LinearAlgebra

    using ..SUT # from SUT_structure.jl

    export construct

    mutable struct construct
    # Creates an undefined struct
    
        x::Matrix{Float64} # Total output
        y::Matrix{Float64} # Final demand
        Z::Matrix{Float64} # Transactions matrix
        A::Matrix{Float64} # Direct requirements matrix [Technical coefficients]
        L::Matrix{Float64} # Total requirements matrix [Leontief inverse]
        G::Matrix{Float64} # Factor use
        R::Matrix{Float64} # Factor intensity matrix
        f::Matrix{Float64} # Total factor use
        pii::Matrix{Float64} # Factor prices
        I_mod::Union{UniformScaling{Bool},Matrix{Float64}} # Augmented identity matrix - not used here
        xhat::Matrix{Float64} # Augmented output matrix - not used here
        isActive
    
        function construct()
            this = new()
            return this
        end
    end

    function CTC(sut::SUT.structure)
        #=
        Commodity technology construct (CTC):
        Creates a struct whose components are defined according to the CTC.
        =#
        m,n = size(sut.V)
        
        if m != n
            @error "The SUT-system is rectangular. Thus, CTC does not work!"
        else
            # Initialise the Constructs struct
            c = construct()
    
            # Calculate the elements of the single-production system
            c.Z = sut.U*inv(sut.D')
            c.A = sut.U*inv(sut.V') # alt: sut.B*inv(sut.C)
            c.L = inv(I-c.A)
            c.G = sut.F*inv(sut.D')
            c.f = sum(c.G,dims=2)
            c.R = sut.F*inv(sut.V')
            c.y = sut.e
            c.x = sut.q
            c.pii = sut.pii
            return c
        end
    end

    function ITC(sut::SUT.structure)
    #=
    Industry technology construct (ITC):
    Creates a struct whose components are defined according to the ITC.
    =#
        
        if sut.t == :"physical"
            @error "The ITC is not applicable to physical SUT-systems."
        else
            # Initialise the Constructs struct
            c = construct()
    
            # Calculate the elements of the single-production system
            c.Z = sut.B*sut.V # alt: sut.U*sut.C'
            c.A = sut.B*sut.D
            c.L = inv(I-c.A)
            c.G = sut.F*sut.C'
            c.f = sum(c.G,dims=2)            
            c.R = sut.S*sut.D
            c.y = sut.e
            c.x = sut.q
            c.pii = sut.pii
            return c
        end
    end

    function FISC(sut::SUT.structure)
    #=
    Fixed industry sales construct (FISC):
    Creates a struct whose components are defined according to the FISC.
    =#
    
        m,n = size(sut.V)
        
        if m != n
            @error "The SUT-system is rectangular. Thus, FISC does not work!"
        else
            # Initialise the Constructs struct
            c = construct()
    
            # Calculate the elements of the single-production system
            c.Z = inv(sut.C)*sut.U
            c.A = inv(sut.C)*sut.B
            c.L = inv(I-c.A)
            c.G = sut.F
            c.f = sum(c.G,dims=2)
            c.R = sut.S
            c.y = inv(sut.C)*sut.e
            c.x = sut.g
            c.pii = sut.pii
            return c
        end
    end

    function FPSC(sut::SUT.structure)
    #=
    Fixed product sales construct (FPSC):
    Creates a struct whose components are defined according to the FPSC.
    =#

        if sut.t == :"physical"
            @error "The FPSC is not applicable to physical SUT-systems."
        else
            # Initialise the Constructs struct
            c = construct()

            # Calculate the elements of the single-production system
            c.Z = sut.D*sut.U
            c.A = sut.D*sut.B
            c.L = inv(I-c.A)
            c.G = sut.F
            c.f = sum(c.G,dims=2)
            c.R = sut.S
            c.y = sut.D*sut.e
            c.x = sut.g
            c.pii = sut.pii
            return c
        end
    end


end