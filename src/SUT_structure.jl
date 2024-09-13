"""
A module as the structure for the elements of a supply-use table (SUT). Additional (intensity) elements are calculated based on absolute SUT data. Changing individual elements after original setup will not recalculate dependent variables.

The module contains the following function:

    structure(U, V, F, e, pii, t; ϕ=nothing)

Returns solution parameters of an RCOT model after optimisation.

### Input

- `U`, `V`, `F`, `e`, `pii` -- matrices and vectors of a SUT.
- `t` -- defaults to nothing; if =="monetary", all row and column sum balances are checked, otherwise only those that are applicable.
- `ϕ` -- factor limits; if not provided, the total usage of a factor is taken as the factor limit.

### Output

An "object" containing the input variables as well as variables derived via calculations.

---

# EXAMPLE:

include("SUT_structure.jl")

### to get the make matrix
foo = <SUT.>structure(U,V,F,e,pii)
foo.V

# or

### to sum up the use matrix and commodity final demand
bar = <SUT.>structure(U,V,F,e,pii;t="physical")
sum(bar.U,dims=2) + bar.e
"""
module SUT

    using LinearAlgebra
    export structure

    mutable struct structure

        U::Matrix{Float64} # Use matrix
        V::Matrix{Float64} # Make matrix (transpose of supply matrix)
        F::Matrix{Float64} # Direct factor requirements
        e::Matrix{Float64} # Commodity final demand
        pii::Matrix{Float64} # Factor prices
        g::Union{Matrix{Float64},Nothing} # Total industry output
        q::Matrix{Float64} # Total commodity output
        f::Matrix{Float64} # Total factor requirements
        ϕ::Union{Matrix{Float64},Nothing} # Factor limits (endowments)
        B::Union{Matrix{Float64},Nothing} # Use coefficients
        C::Union{Matrix{Float64},Nothing} # 
        D::Matrix{Float64} # Industry share
        S::Union{Matrix{Float64},Nothing} # Factor intensities
        t::Union{String,Nothing} # Unit of commodity-related SUT elements
        isActive

        function structure(U, V, F, e, pii, t; ϕ=nothing)
            if size(V) != size(U')
                @error "The make and use matrices have different dimensions."
            elseif size(V,1) != size(F,2)
                @error "The factor exchanges have a different industry dimension than the make and use matrices."
            end
            
            this = new()
            try 
                #SUT type: monetary, physical, or mixed
                this.t = t
                #SUT system
                this.U = U
                this.V = V
                this.F = F
                this.e = e
                this.pii = pii
                this.q = sum(V',dims=2)
                this.f = sum(F,dims=2)
                isnothing(ϕ) && (this.ϕ = this.f)
                this.D = V*inv(diagm(vec(this.q)))
                
                # Calculate the following only when data is given in monetary units
                if this.t == :"monetary"
                    this.g = sum(V,dims=2)
                    this.B = U*inv(diagm(vec(this.g)))
                    this.C = V'*inv(diagm(vec(this.g)))
                    this.S = F*inv(diagm(vec(this.g)))

                    if sum(this.V',dims=2) != sum(this.U,dims=2) + this.e && sum(this.V,dims=2) != transpose(sum(this.U,dims=1) + this.pii'*this.F)
                        @warn("The SUT-system is not balanced.")
                    end
                else
                    this.g = nothing
                    this.B = nothing
                    this.C = nothing
                    this.S = nothing
                    @info "The SUT system is not given in monetary units such that no total industry output and dependent matrices may be calculated."
                    sum(this.V',dims=2) == sum(this.U,dims=2) + this.e || @warn("The SUT-system is not balanced.")
                end

            catch
                rethrow()
            end

            @info("A structure for supply-use elements was set up. Changing individual elements will not change others automatically.")
            return this
        end
    end
end