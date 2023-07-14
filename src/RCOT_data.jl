module RCOT_data
#=
Sets up the data structure to be used for IO/SU RCOT modelling.
The base data can then be augmented with data for additional technologies.
It is important to note that the data elements are treated independently.
For example, intensity values are not recalculated when absolute ones change, 
even when the former were earlier derived form the latter.

---

# usage as for example:

include("RCOT_data.jl")

### setup the base data, i.e. copy it from existing SUT.structure
io_rcot = RCOT_data.SU(sut)

### setup the base data, i.e. copy it from existing Construct.construct
su_rcot = RCOT_data.IO(itc)

### the base data can later be augmented, e.g.:
V2_alt = [0 95 0 0 0; 0 95 0 0 0; 10 60 0 0 0] # alternative technologies for industry #i.2
V3_alt = [0 0 0 0 10] # alternative technology for industry #i.3
su_rcot.V = @views [su_rcot.V[1:2, :]; V2_alt; su_rcot.V[3:end, :]; V3_alt]

=#

    using LinearAlgebra
    using ..SUT # from SUT_structure.jl
    using ..Constructs # from Constructs.jl

    export io, su

    mutable struct io
    # Creates an undefined struct
        
        isActive

        function io()
            this = new()
            @info "You are setting up an IO-RCOT dataset. Elements of this dataset are now treated independently, 
            meaning that no recalculation whatsoever takes place when individual elements are changed."
            return this
        end

    end

    mutable struct su
    # Creates an undefined struct
            
        isActive
    
        function su()
            this = new()
            @info "You are setting up an SU-RCOT dataset. Elements of this dataset are now treated independently, 
            meaning that no recalculation whatsoever takes place when individual elements are changed."
            return this
        end
    end

    function IO(construct::Constructs.construct)
        #=
        IO-RCOT data:
        Creates a struct with base data according to the chosen construct, and which may be augmented.
        =#
       
        # Initialise the IO-RCOT struct
        io_rcot_data = io()

        # Copy the construct data and add dummy identity matrix
        io_rcot_data = deepcopy(construct)
        io_rcot_data.I_mod = I
        io_rcot_data.xhat = Diagonal(vec(io_rcot_data.x))

        return io_rcot_data
    end

    function SU(sut::structure)
    #=
    SU-RCOT data:
    Creates a struct with base data copied from <sut>, the elements of which may be augmented.
    =#
        
        # Initialise the SU-RCOT struct
        su_rcot_data = su()

        # Copy the construct data
        su_rcot_data = deepcopy(sut)

        return su_rcot_data
    end

end