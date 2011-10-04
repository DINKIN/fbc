'' main module, FreeBSD front-end
''
'' chng: jul/2007 written [DrV]


#include once "fb.bi"
#include once "fbint.bi"
#include once "fbc.bi"
#include once "hlp.bi"

enum GCC_LIB
	CRT1_O
	CRTBEGIN_O
	CRTEND_O
	CRTI_O
	CRTN_O
	GCRT1_O
	LIBGCC_A
	LIBSUPC_A
	GCC_LIBS
end enum

'':::::
private sub _setDefaultLibPaths

	'' only query gcc if this is not a cross compile
	if( fbIsCrossComp() = FALSE ) then
		dim as string file_loc
		dim as integer i = any

		'' add the paths required by gcc libs and object files
		for i = 0 to GCC_LIBS - 1

			file_loc = fbFindGccLib( i )

			if( len( file_loc ) <> 0 ) then
				fbSetGccLib( i, file_loc )
				fbcAddDefLibPath( hStripFilename( file_loc ) )
			end if
		next 

	else
		dim as integer i = any
		for i = 0 to GCC_LIBS - 1
			fbSetGccLib( i, fbFindGccLib( i ) )
		next
	endif

end sub

'':::::
private function _linkFiles _
	( _
	) as integer

	dim as string ldpath, ldcline, dllname
	dim as integer res = any

	function = FALSE

	'' set path
	ldpath = fbFindBinFile( "ld" )
	if( len( ldpath ) = 0 ) then
		exit function
	end if

	if( fbGetOption( FB_COMPOPT_OUTTYPE ) = FB_OUTTYPE_DYNAMICLIB ) then
		dllname = hStripPath( hStripExt( fbc.outname ) )
	end if

	'' add extension
	if( fbc.outaddext ) then
		select case fbGetOption( FB_COMPOPT_OUTTYPE )
		case FB_OUTTYPE_DYNAMICLIB
			fbc.outname = hStripFilename( fbc.outname ) + "lib" + hStripPath( fbc.outname ) + ".so"
		end select
	end if

	if( fbGetOption( FB_COMPOPT_OUTTYPE ) = FB_OUTTYPE_DYNAMICLIB ) then
		ldcline = "-shared --export-dynamic -h" + hStripPath( fbc.outname )
	else
		ldcline = "-dynamic-linker /libexec/ld-elf.so.1"

		'' tell LD to add all symbols declared as EXPORT to the symbol table
		if( fbGetOption( FB_COMPOPT_EXPORT ) ) then
			ldcline += " --export-dynamic"
		end if
	end if

#ifndef DISABLE_OBJINFO
	'' Supplementary ld script to drop the fbctinf objinfo section
	ldcline += " " + QUOTE + fbGetPath( FB_PATH_LIB ) + "fbextra.x" + QUOTE
#endif

	if( len( fbc.mapfile ) > 0 ) then
		ldcline += " -Map " + fbc.mapfile
	end if

	''
	if( fbGetOption( FB_COMPOPT_DEBUG ) = FALSE ) then
		if( fbGetOption( FB_COMPOPT_PROFILE ) = FALSE ) then
			ldcline += " -s"
		end if
	end if

	'' add library search paths
	ldcline += *fbcGetLibPathList( )

	'' crt init stuff
	if( fbGetOption( FB_COMPOPT_OUTTYPE ) = FB_OUTTYPE_EXECUTABLE) then
		if( fbGetOption( FB_COMPOPT_PROFILE ) ) then
			ldcline += " " + QUOTE + fbGetGccLib( GCRT1_O ) + QUOTE
		else
			ldcline += " " + QUOTE + fbGetGccLib( CRT1_O ) + QUOTE
		end if
	end if

	ldcline += " " + QUOTE + fbGetGccLib( CRTI_O ) + QUOTE
	ldcline += " " + QUOTE + fbGetGccLib( CRTBEGIN_O ) + QUOTE + " "

	'' add objects from output list
	dim as FBC_IOFILE ptr iof = listGetHead( @fbc.inoutlist )
	do while( iof <> NULL )
		ldcline += QUOTE + iof->outf + (QUOTE + " ")
		iof = listGetNext( iof )
	loop

	'' add objects from cmm-line
	dim as string ptr objf = listGetHead( @fbc.objlist )
	do while( objf <> NULL )
		ldcline += QUOTE + *objf + (QUOTE + " ")
		objf = listGetNext( objf )
	loop

	'' set executable name
	ldcline += "-o " + QUOTE + fbc.outname + QUOTE

	'' init lib group
	ldcline += " -( "

	'' add libraries from cmm-line and found when parsing
	ldcline += *fbcGetLibList( dllname )

	if( fbGetOption( FB_COMPOPT_NODEFLIBS ) = FALSE ) then
		'' rtlib initialization and termination (must be included in the group or
		'' dlopen() will fail because fb_hRtExit() will be undefined)
		ldcline += QUOTE + fbGetPath( FB_PATH_LIB ) + "fbrt0.o" + QUOTE + " "
	end if

	'' end lib group
	ldcline += "-) "

	'' crt end stuff
	ldcline += QUOTE + fbGetGccLib( CRTEND_O ) + QUOTE
	ldcline += " " + QUOTE + fbGetGccLib( CRTN_O ) + QUOTE

   	'' extra options
   	ldcline += fbc.extopt.ld

	'' invoke ld
	if( fbc.verbose ) then
		print "linking: ", ldcline
	end if

	res = exec( ldpath, ldcline )
	if( res <> 0 ) then
		if( fbc.verbose ) then
			print "linking failed: error code " & res
		end if
		exit function
	end if

	function = TRUE

end function

'':::::
private function _archiveFiles( byval cmdline as zstring ptr ) as integer
	dim arcpath as string

	arcpath = fbFindBinFile( "ar" )
	if( len( arcpath ) = 0 ) then
		return FALSE
	end if

	if( exec( arcpath, *cmdline ) <> 0 ) then
		return FALSE
	end if

	return TRUE

end function

'':::::
private sub _getDefaultLibs _
	( _
		byval dstlist as TLIST ptr, _
		byval dsthash as THASH ptr _
	)

#macro hAddLib( libname )
	symbAddLibEx( dstlist, dsthash, libname, TRUE )
#endmacro

	hAddLib( "c" )
	hAddLib( "m" )
	hAddLib( "pthread" )
	hAddLib( "ncurses" )
	hAddLib( "supc++" )

end sub


'':::::
private sub _addGfxLibs _
	( _
	)

#ifdef __FB_FREEBSD__
	symbAddLibPath( "/usr/X11R6/lib" )
#endif

	symbAddLib( "X11" )
	symbAddLib( "Xext" )
	symbAddLib( "Xpm" )
	symbAddLib( "Xrandr" )
	symbAddLib( "Xrender" )

end sub


'':::::
private function _getCStdType _
	( _
		byval ctype as FB_CSTDTYPE _
	) as integer

	if( ctype = FB_CSTDTYPE_SIZET ) then
		function = FB_DATATYPE_UINT
	end if

end function


'':::::
function fbcInit_freebsd( ) as integer

    static as FBC_VTBL vtbl = _
    ( _
		@_linkFiles, _
		@_archiveFiles, _
		@_setDefaultLibPaths, _
		@_getDefaultLibs, _
		@_addGfxLibs, _
		@_getCStdType _
	)

	fbc.vtbl = vtbl

	fbAddGccLib( @"crt1.o", CRT1_O )
	fbAddGccLib( @"crtbegin.o", CRTBEGIN_O )
	fbAddGccLib( @"crtend.o", CRTEND_O )
	fbAddGccLib( @"crti.o", CRTI_O )
	fbAddGccLib( @"crtn.o", CRTN_O )
	fbAddGccLib( @"gcrt1.o", GCRT1_O )
	fbAddGccLib( @"libgcc.a", LIBGCC_A )
	fbAddGccLib( @"libsupc++.a", LIBSUPC_A )

	env.target.wchar.type = FB_DATATYPE_UINT
	env.target.wchar.size = FB_INTEGERSIZE

	env.target.triplet = @ENABLE_FREEBSD
	env.target.define = @"__FB_FREEBSD__"
	env.target.entrypoint = @"main"
	env.target.underprefix = FALSE
	env.target.constsection = @"rodata"

    '' Default calling convention, must match the rtlib's FBCALL
    env.target.fbcall = FB_FUNCMODE_CDECL

    '' Specify whether stdcall or EXTERN "windows" result in STDCALL (with @N),
    '' or STDCALL_MS (without @N).
    env.target.stdcall = FB_FUNCMODE_STDCALL_MS

	return TRUE

end function
