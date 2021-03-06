#include "fbcunit.bi"

SUITE( fbc_tests.wstrings.instr_0 )

	TEST( wholeString )

		CU_ASSERT_EQUAL( 0 , instr(wstr("asd"+chr(0)), wstr(chr(0))) )
		CU_ASSERT_EQUAL( 3 , instr(wstr("asd"+chr(0)), wstr("d")) )
		CU_ASSERT_EQUAL( 1 , instr(wstr("asd"+chr(0)), wstr("a")) )
		CU_ASSERT_EQUAL( 2 , instr(wstr("asd"+chr(0)), wstr("sd")) )
		CU_ASSERT_EQUAL( 0 , instr(wstr("asd"+chr(0)), wstr("")) )
		CU_ASSERT_EQUAL( 0 , instr(wstr("asd"+chr(0)), wstr("asdfg")) )
		CU_ASSERT_EQUAL( 0 , instr(wstr("asd"+chr(0)), wstr("qwe")) )
		CU_ASSERT_EQUAL( 0 , instr(wstr(""), wstr("asdf")) )
		CU_ASSERT_EQUAL( 0 , instr(wstr(""), wstr("")) )

	END_TEST

	TEST( partialString )

		CU_ASSERT_EQUAL( 0 , instr(2, wstr("asd"+chr(0)), wstr(chr(0))) )
		CU_ASSERT_EQUAL( 3 , instr(2, wstr("asd"+chr(0)), wstr("d")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr("asd"+chr(0)), wstr("a")) )
		CU_ASSERT_EQUAL( 2 , instr(2, wstr("asd"+chr(0)), wstr("sd")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr("asd"+chr(0)), wstr("")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr("asd"+chr(0)), wstr("asdfg")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr("asd"+chr(0)), wstr("qwe")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr(""), wstr("asdf")) )
		CU_ASSERT_EQUAL( 0 , instr(2, wstr(""), wstr("")) )

	END_TEST

	#define DoTest( s1, s2, start, exp_result ) _
		CU_ASSERT_EQUAL( exp_result, Instr(start,wstr(s1),wstr(s2)) )

	TEST( checkEveryInputValue )

		dim a as string 
		dim b as string 

		a = "thes is the the string"
		b = "the"

		DoTest( a, b, 23, 0 )
		DoTest( a, b, 22, 0 )
		DoTest( a, b, 21, 0 )
		DoTest( a, b, 20, 0 )
		DoTest( a, b, 19, 0 )
		DoTest( a, b, 18, 0 )
		DoTest( a, b, 17, 0 )
		DoTest( a, b, 16, 0 )
		DoTest( a, b, 15, 0 )
		DoTest( a, b, 14, 0 )
		DoTest( a, b, 13, 13 )
		DoTest( a, b, 12, 13 )
		DoTest( a, b, 11, 13 )
		DoTest( a, b, 10, 13 )
		DoTest( a, b, 9, 9 )
		DoTest( a, b, 8, 9 )
		DoTest( a, b, 7, 9 )
		DoTest( a, b, 6, 9 )
		DoTest( a, b, 5, 9 )
		DoTest( a, b, 4, 9 )
		DoTest( a, b, 3, 9 )
		DoTest( a, b, 2, 9 )
		DoTest( a, b, 1, 1 )
		DoTest( a, b, 0, 0 )
		DoTest( a, b, -1, 0 )

		a = "the xxx"
		b = "the"

		DoTest( a, b, 8, 0 )
		DoTest( a, b, 7, 0 )
		DoTest( a, b, 6, 0 )
		DoTest( a, b, 5, 0 )
		DoTest( a, b, 4, 0 )
		DoTest( a, b, 3, 0 )
		DoTest( a, b, 2, 0 )
		DoTest( a, b, 1, 1 )
		DoTest( a, b, 0, 0 )
		DoTest( a, b, -1, 0 )

		a = "xxx the"
		b = "the"

		DoTest( a, b, 8, 0 )
		DoTest( a, b, 7, 0 )
		DoTest( a, b, 6, 0 )
		DoTest( a, b, 5, 5 )
		DoTest( a, b, 4, 5 )
		DoTest( a, b, 3, 5 )
		DoTest( a, b, 2, 5 )
		DoTest( a, b, 1, 5 )
		DoTest( a, b, 0, 0 )
		DoTest( a, b, -1, 0 )

		a = "xxx"
		b = "xxx"

		DoTest( "", "", 0, 0 )
		DoTest( a , "", 0, 0 )
		DoTest( "",  b, 0, 0 )

	END_TEST

END_SUITE
