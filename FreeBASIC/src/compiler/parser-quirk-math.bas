''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2006 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' quirk math functions (ABS, SGN, FIX, LEN, ...) parsing
''
'' chng: sep/2004 written [v1ctor]

option explicit
option escape

#include once "inc\fb.bi"
#include once "inc\fbint.bi"
#include once "inc\parser.bi"
#include once "inc\rtl.bi"
#include once "inc\ast.bi"

'':::::
'' cMathFunct	=	ABS( Expression )
'' 				|   SGN( Expression )
''				|   FIX( Expression )
''				|   INT( Expression )
''				|	LEN( data type | Expression ) .
''
function cMathFunct _
	( _
		byref funcexpr as ASTNODE ptr _
	) as integer

    dim as ASTNODE ptr expr, expr2
    dim as integer islen, typ, lgt, ptrcnt, op
    dim as FBSYMBOL ptr sym, subtype

	function = FALSE

	select case as const lexGetToken( )
	'' ABS( Expression )
	case FB_TK_ABS
		lexSkipToken( )

		hMatchLPRNT( )

		hMatchExpressionEx( expr, FB_DATATYPE_INTEGER )

		hMatchRPRNT( )

		'' hack! implemented as Unary OP for better speed on x86's
		funcexpr = astNewUOP( AST_OP_ABS, expr )
		if( funcexpr = NULL ) then
			if( errReport( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			else
				funcexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
		end if

		function = TRUE

	'' SGN( Expression )
	case FB_TK_SGN
		lexSkipToken( )

		hMatchLPRNT( )

		hMatchExpressionEx( expr, FB_DATATYPE_INTEGER )

		hMatchRPRNT( )

		'' hack! implemented as Unary OP for better speed on x86's
		funcexpr = astNewUOP( AST_OP_SGN, expr )
		if( funcexpr = NULL ) then
			if( errReport( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			else
				funcexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
		end if

		function = TRUE

	'' FIX( Expression )
	case FB_TK_FIX
		lexSkipToken( )

		hMatchLPRNT( )

		hMatchExpressionEx( expr, FB_DATATYPE_INTEGER )

		hMatchRPRNT( )

		funcexpr = rtlMathFIX( expr )
		if( funcexpr = NULL ) then
			if( errReport( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			else
				funcexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
		end if

		function = TRUE

	'' SIN/COS/...( Expression )
	case FB_TK_SIN, FB_TK_ASIN, FB_TK_COS, FB_TK_ACOS, FB_TK_TAN, FB_TK_ATN, _
		 FB_TK_SQR, FB_TK_LOG, FB_TK_INT

		select case as const lexGetToken( )
		case FB_TK_SIN
			op = AST_OP_SIN
		case FB_TK_ASIN
			op = AST_OP_ASIN
		case FB_TK_COS
			op = AST_OP_COS
		case FB_TK_ACOS
			op = AST_OP_ACOS
		case FB_TK_TAN
			op = AST_OP_TAN
		case FB_TK_ATN
			op = AST_OP_ATAN
		case FB_TK_SQR
			op = AST_OP_SQRT
		case FB_TK_LOG
			op = AST_OP_LOG
		case FB_TK_INT
			op = AST_OP_FLOOR
		end select

		lexSkipToken( )

		hMatchLPRNT( )

		hMatchExpressionEx( expr, FB_DATATYPE_INTEGER )

		hMatchRPRNT( )

		'' hack! implemented as Unary OP for better speed on x86's
		funcexpr = astNewUOP( op, expr )
		if( funcexpr = NULL ) then
			if( errReport( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			else
				funcexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
		end if

		function = TRUE

	'' ATAN2( Expression ',' Expression )
	case FB_TK_ATAN2
		lexSkipToken( )

		hMatchLPRNT( )

		hMatchExpressionEx( expr, FB_DATATYPE_INTEGER )

		hMatchCOMMA( )

		hMatchExpressionEx( expr2, FB_DATATYPE_INTEGER )

		hMatchRPRNT( )

		'' hack! implemented as Binary OP for better speed on x86's
		funcexpr = astNewBOP( AST_OP_ATAN2, expr, expr2 )
		if( funcexpr = NULL ) then
			if( errReport( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			else
				funcexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
		end if

		function = TRUE

	'' LEN|SIZEOF( data type | Expression{idx-less arrays too} )
	case FB_TK_LEN, FB_TK_SIZEOF
		islen = (lexGetToken( ) = FB_TK_LEN)
		lexSkipToken( )

		hMatchLPRNT( )

		expr = NULL
		if( cSymbolType( typ, subtype, lgt, ptrcnt, FB_SYMBTYPEOPT_NONE ) = FALSE ) then
			env.checkarray = FALSE
			if( cExpression( expr ) = FALSE ) then
				env.checkarray = TRUE
				if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
					exit function
				else
					'' error recovery: fake an expr
					expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
				end if
			end if
			env.checkarray = TRUE
		end if

		'' string expressions with SIZEOF() are not allowed
		if( expr <> NULL ) then
			if( islen = FALSE ) then
				if( astGetDataClass( expr ) = FB_DATACLASS_STRING ) then
					if( (astGetSymbol( expr ) = NULL) or (astIsFUNCT( expr )) ) then
						if( errReport( FB_ERRMSG_EXPECTEDIDENTIFIER, TRUE ) = FALSE ) then
							exit function
						else
							'' error recovery: fake an expr
							astDelTree( expr )
							expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
						end if
					end if
				end if
			end if
		end if

		hMatchRPRNT( )

		if( expr <> NULL ) then
			funcexpr = rtlMathLen( expr, islen )
		else
			funcexpr = astNewCONSTi( lgt, FB_DATATYPE_INTEGER )
		end if

		function = TRUE

	end select

end function

