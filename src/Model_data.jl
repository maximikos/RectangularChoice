module Model_data
#=
Sets up the data structure to be used for inversion-based or IO/SU RCOT modelling. The base data can then be modified and (in the case of RCOT) augmented with data for additional technologies. It is important to note that the data elements are treated independently. For example, intensity values are not recalculated when absolute ones change, even when the former were earlier derived form the latter.

---

# usage as for example:

include("Model_data.jl")

### setup the base data for IO-based Leontief model, i.e. copy it from existing SUT.structure
io_leontief = Model_data.IO(ctc)

### setup the base data for SU-RCOT, i.e. copy it from existing SUT.structure
su_rcot = Model_data.SU(sut)

### setup the base data for IO-RCOT, i.e. copy it from existing Construct.construct
io_rcot = Model_data.IO(itc)

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
            @info "You are setting up an IO model dataset. Elements of this dataset are now treated independently, meaning that no recalculation whatsoever takes place when individual elements are changed."
            return this
        end

    end

    mutable struct su
    # Creates an undefined struct
            
        isActive
    
        function su()
            this = new()
            @info "You are setting up an SU model dataset. Elements of this dataset are now treated independently, meaning that no recalculation whatsoever takes place when individual elements are changed."
            return this
        end
    end

    function IO(construct::Constructs.construct)
    #=
    IO data:
    Creates a struct with base data according to the chosen construct, and which may be modified and augmented.
    =#
       
        # Initialise the IO struct
        io_model_data = io()

        # Copy the construct data and add dummy identity matrix
        io_model_data = deepcopy(construct)
        io_model_data.I_mod = Matrix(I, size(io_model_data.A)) 
        io_model_data.xhat = Diagonal(vec(io_model_data.x))

        return io_model_data
    end

    function SU(sut::structure)
    #=
    SU data:
    Creates a struct with base data copied from <sut>, the elements of which may be modified and augmented.
    =#
        
        # Initialise the SU struct
        su_model_data = su()

        # Copy the construct data
        su_model_data = deepcopy(sut)

        return su_model_data
    end

end