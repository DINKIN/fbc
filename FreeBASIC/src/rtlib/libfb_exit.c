/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2005 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and others.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * exit.c -- end and system routines
 *
 * chng: oct/2004 written [v1ctor]
 *
 */

#include <stdlib.h>
#include "fb.h"

char *fb_error_message = NULL;


/*:::::*/
FBCALL void fb_End ( int errlevel )
{
	/* do nothing, real job is done at fb_RtExit(), invoked by atexit() */

	exit( errlevel );
}


/*:::::*/
void fb_RtExit ( void )
{
#ifdef MULTITHREADED
    int i;
#endif

	/* os-dep termination */
	fb_hEnd( 0 );

#ifdef MULTITHREADED
	/* free thread local storage plus the keys */
	for( i = 0; i < FB_TLSKEYS; i++ )
	{
     	fb_TlsDelCtx( i );

		/* del key/index */
		FB_TLSFREE( fb_tls_ctxtb[i] );
	}
#endif

	/* if an error has to be displayed, do it now */
	if( fb_error_message )
		fprintf( stderr, fb_error_message );
}


