' TEST_MODE : COMPILE_ONLY_FAIL

type T
	as string s
end type

dim as T x

const s = "test"
let(s) = x
