package foo20

import (
	"std"
	"strings"

	"gno.land/p/grc/grc20"
	"gno.land/p/ufmt"
	"gno.land/r/users"
)

var (
	foo   *grc20.Token
	admin std.Address = "g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj" // TODO: helper to change admin
)

func init() {
	foo = grc20.NewToken("Foo", "FOO", 4)
	foo.Mint(admin, 1000000*10000)                                    // @administrator (1M)
	foo.Mint("g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq", 10000*10000) // @manfred (10k)
}

// method proxies as public functions.
//

// getters.

func TotalSupply() uint64 {
	return foo.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	return foo.BalanceOf(owner.Resolve())
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	return foo.Allowance(owner.Resolve(), spender.Resolve())
}

// setters.

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	foo.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

// administration.

func Mint(address users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	assertIsAdmin(caller)
	foo.Mint(address.Resolve(), amount)
}

func Burn(address users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	assertIsAdmin(caller)
	foo.Burn(address.Resolve(), amount)
}

// render.
//

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return foo.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance := foo.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}
