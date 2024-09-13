"""
A module for setting up the data structure to be used for inversion-based or S-/J-RCOT modelling. The base data can then be modified and (in the case of RCOT) augmented with data for additional technologies. It is important to note that the data elements are treated independently. For example, intensity values are not recalculated when absolute ones change, even when the former were earlier derived form the latter.

The functions su() and io() initialise the SUT and IOT data structures. These structures are then exported.
"""
module Model_data

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

    """
        IO(construct::Constructs.construct)

    Creates a struct with base data according to the chosen construct, and which may be modified and augmented.

    ### Input

    - `construct` -- the IOT data to be used.

    ### Output

    Returns the IOT data as an object.

    ### Example
    include("Model_data.jl")

    # setup the base data for IO-based Leontief model, i.e. copy it from existing <Constructs.construct> (here: based on CTC)
    io_leontief = Model_data.IO(ctc)

    # setup the base data for S-RCOT, i.e. copy it from existing <Constructs.construct> (here: based on ITC)
    io_rcot = Model_data.IO(itc)
    """
    function IO(construct::Constructs.construct)
       
        # Initialise the IO struct
        io_model_data = io()

        # Copy the construct data and add dummy identity matrix
        io_model_data = deepcopy(construct)
        io_model_data.I_mod = Matrix(I, size(io_model_data.A)) 
        io_model_data.xhat = Diagonal(vec(io_model_data.x))

        return io_model_data
    end

    """
        SU(sut::structure)

    Creates a struct with base data copied from <sut>, the elements of which may be modified and augmented.

    ### Input

    - `sut` -- the SUT data to be used.

    ### Output

    Returns the SUT data as an object.

    ### Example
    
    include("Model_data.jl")

    # setup the base data for J-RCOT, i.e. copy it from existing SUT.structure
    su_rcot = Model_data.SU(sut)

    # the base data can later be augmented, e.g.:
    V2_alt = [0 95 0 0 0; 0 95 0 0 0; 10 60 0 0 0] # alternative technologies for industry #i.2
    V3_alt = [0 0 0 0 10] # alternative technology for industry #i.3
    su_rcot.V = @views [su_rcot.V[1:2, :]; V2_alt; su_rcot.V[3:end, :]; V3_alt]
    """
    function SU(sut::structure)
        
        # Initialise the SU struct
        su_model_data = su()

        # Copy the construct data
        su_model_data = deepcopy(sut)

        return su_model_data
    end

end