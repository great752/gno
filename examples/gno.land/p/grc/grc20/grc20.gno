package grc20

import (
	"std"

	"gno.land/p/avl"
	"gno.land/p/ufmt"
)

// FIXME: helper that creates a Permissionless instance of the token (without mint, and with caller as address).

type Token struct {
	IGRC20 // implements the GRC20 interface

	name        string
	symbol      string
	decimals    uint
	totalSupply uint64
	balances    *avl.MutTree // std.Address(owner) -> uint64
	allowances  *avl.MutTree // string(owner+":"+spender) -> uint64
}

func NewToken(name, symbol string, decimals uint) *Token {
	// FIXME: check for limits

	return &Token{
		name:     name,
		symbol:   symbol,
		decimals: decimals,

		balances:   avl.NewMutTree(),
		allowances: avl.NewMutTree(),
	}
}

const zeroAddress = std.Address("")

// GRC20 implementation.
//

// TODO: create a reusable interface with optional hooks.
// TODO: simplify the API and try to use events when available.
// TODO: useful Render() method.
// TODO: add a lot of unit tests, really a lot.

func (t *Token) GetName() string     { return t.name }
func (t *Token) GetSymbol() string   { return t.symbol }
func (t *Token) GetDecimals() uint   { return t.decimals }
func (t *Token) TotalSupply() uint64 { return t.totalSupply }

func (t *Token) BalanceOf(owner std.Address) uint64 {
	return t.balanceOf(owner)
}

func (t *Token) Transfer(owner, to std.Address, amount uint64) {
	t.transfer(owner, to, amount)
}

func (t *Token) Allowance(owner, spender std.Address) uint64 {
	return t.allowance(owner, spender)
}

func (t *Token) Approve(owner, spender std.Address, amount uint64) {
	t.approve(owner, spender, amount)
}

func (t *Token) TransferFrom(spender, from, to std.Address, amount uint64) {
	t.spendAllowance(from, spender, amount)
	t.transfer(from, to, amount)
}

// Administration helpers implementation.
//

func (t *Token) Mint(to std.Address, amount uint64) {
	t.mint(to, amount)
}

func (t *Token) Burn(from std.Address, amount uint64) {
	t.burn(from, amount)
}

// private helpers
//

func (t *Token) mint(address std.Address, amount uint64) {
	checkIsValidAddress(address)
	// TODO: check for overflow

	t.totalSupply += amount
	currentBalance := t.balanceOf(address)
	newBalance := currentBalance + amount

	t.balances.Set(string(address), newBalance)

	event := TransferEvent{zeroAddress, address, amount}
	emit(&event)
}

func (t *Token) burn(address std.Address, amount uint64) {
	checkIsValidAddress(address)
	// TODO: check for overflow

	currentBalance := t.balanceOf(address)
	if currentBalance < amount {
		panic("insufficient balance")
	}

	t.totalSupply -= amount
	newBalance := currentBalance - amount

	t.balances.Set(string(address), newBalance)

	event := TransferEvent{address, zeroAddress, amount}
	emit(&event)
}

func (t *Token) balanceOf(address std.Address) uint64 {
	checkIsValidAddress(address)

	balance, found := t.balances.Get(address.String())
	if !found {
		return 0
	}
	return balance.(uint64)
}

func (t *Token) spendAllowance(owner, spender std.Address, amount uint64) {
	checkIsValidAddress(owner)
	checkIsValidAddress(spender)

	currentAllowance := t.allowance(owner, spender)
	if currentAllowance < amount {
		panic("insufficient allowance")
	}
}

func (t *Token) transfer(from, to std.Address, amount uint64) {
	checkIsValidAddress(from)
	checkIsValidAddress(to)

	if from == to {
		panic("cannot send transfer to self")
	}

	toBalance := t.balanceOf(to)
	fromBalance := t.balanceOf(from)

	if fromBalance < amount {
		panic("insufficient balance")
	}

	newToBalance := toBalance + amount
	newFromBalance := fromBalance - amount

	t.balances.Set(string(to), newToBalance)
	t.balances.Set(string(from), newFromBalance)

	event := TransferEvent{from, to, amount}
	emit(&event)
}

func (t *Token) allowance(owner, spender std.Address) uint64 {
	checkIsValidAddress(owner)
	checkIsValidAddress(spender)

	key := owner.String() + ":" + spender.String()

	allowance, found := t.allowances.Get(key)
	if !found {
		return 0
	}

	return allowance.(uint64)
}

func (t *Token) approve(owner, spender std.Address, amount uint64) {
	checkIsValidAddress(owner)
	checkIsValidAddress(spender)

	key := owner.String() + ":" + spender.String()
	t.allowances.Set(key, amount)

	event := ApprovalEvent{owner, spender, amount}
	emit(&event)
}

func checkIsValidAddress(addr std.Address) {
	if addr.String() == "" {
		panic("invalid address")
	}
}

func (t *Token) RenderHome() string {
	str := ""
	str += ufmt.Sprintf("# %s ($%s)\n\n", t.name, t.symbol)
	str += ufmt.Sprintf("* **Decimals**: %d\n", t.decimals)
	str += ufmt.Sprintf("* **Total supply**: %d\n", t.totalSupply)
	str += ufmt.Sprintf("* **Known accounts**: %d\n", t.balances.Size())
	return str
}

func emit(event interface{}) {
	// TODO: should we do something there?
	// noop
}
