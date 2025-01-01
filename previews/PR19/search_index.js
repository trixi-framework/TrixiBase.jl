var documenterSearchIndex = {"docs":
[{"location":"license/","page":"License","title":"License","text":"EditURL = \"https://github.com/trixi-framework/TrixiBase.jl/blob/main/LICENSE.md\"","category":"page"},{"location":"license/#License","page":"License","title":"License","text":"","category":"section"},{"location":"license/","page":"License","title":"License","text":"MIT LicenseCopyright (c) 2020-present The Trixi.jl Authors (see Authors)Permission is hereby granted, free of charge, to any person obtaining a copy   of this software and associated documentation files (the \"Software\"), to deal   in the Software without restriction, including without limitation the rights   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell   copies of the Software, and to permit persons to whom the Software is   furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all   copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE   SOFTWARE.","category":"page"},{"location":"authors/","page":"Authors","title":"Authors","text":"EditURL = \"https://github.com/trixi-framework/TrixiBase.jl/blob/main/AUTHORS.md\"","category":"page"},{"location":"authors/#Authors","page":"Authors","title":"Authors","text":"","category":"section"},{"location":"authors/","page":"Authors","title":"Authors","text":"This package is maintained by the authors of Trixi.jl. For a full list of authors, see AUTHORS.md in the Trixi.jl repository. These authors form \"The Trixi.jl Authors\", as mentioned under License.","category":"page"},{"location":"reference/#API-reference","page":"API reference","title":"API reference","text":"","category":"section"},{"location":"reference/","page":"API reference","title":"API reference","text":"CurrentModule = TrixiBase","category":"page"},{"location":"reference/","page":"API reference","title":"API reference","text":"Modules = [TrixiBase]","category":"page"},{"location":"reference/#TrixiBase.trixi_include-Tuple{Module, AbstractString}","page":"API reference","title":"TrixiBase.trixi_include","text":"trixi_include([mod::Module=Main,] elixir::AbstractString; kwargs...)\n\ninclude the file elixir and evaluate its content in the global scope of module mod. You can override specific assignments in elixir by supplying keyword arguments. Its basic purpose is to make it easier to modify some parameters while running simulations from the REPL. Additionally, this is used in tests to reduce the computational burden for CI while still providing examples with sensible default values for users.\n\nBefore replacing assignments in elixir, the keyword argument maxiters is inserted into calls to solve with it's default value used in the SciML ecosystem for ODEs, see the \"Miscellaneous\" section of the documentation.\n\nExamples\n\njulia> using TrixiBase, Trixi\n\njulia> redirect_stdout(devnull) do\n         trixi_include(@__MODULE__, joinpath(examples_dir(), \"tree_1d_dgsem\", \"elixir_advection_extended.jl\"),\n                       tspan=(0.0, 0.1))\n         sol.t[end]\n       end\n[ Info: You just called `trixi_include`. Julia may now compile the code, please be patient.\n0.1\n\n\n\n\n\n","category":"method"},{"location":"","page":"Home","title":"Home","text":"EditURL = \"https://github.com/trixi-framework/TrixiBase.jl/blob/main/README.md\"","category":"page"},{"location":"#TrixiBase.jl","page":"Home","title":"TrixiBase.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(Image: Docs-stable) (Image: Docs-dev) (Image: Build Status) (Image: Coveralls) (Image: Codecov) (Image: Aqua QA) (Image: License: MIT)","category":"page"},{"location":"","page":"Home","title":"Home","text":"TrixiBase.jl  provides common functionality used by multiple Julia packages in the Trixi Framework.","category":"page"}]
}