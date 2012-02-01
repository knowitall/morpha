%{
  /*
   morpha.lex - morphological analyser / lemmatiser

   Copyright (c) 1995-2001 University of Sheffield, University of Sussex
   All rights reserved.

   Redistribution and use of source and derived binary forms are
   permitted provided that: 
   - they are not  used in commercial products
   - the above copyright notice and this paragraph are duplicated in
   all such forms
   - any documentation, advertising materials, and other materials
   related to such distribution and use acknowledge that the software
   was developed by Kevin Humphreys <kwh@dcs.shef.ac.uk> and John
   Carroll <john.carroll@cogs.susx.ac.uk> and Guido Minnen
   <Guido.Minnen@cogs.susx.ac.uk> and refer to the following related
   publication:

     Guido Minnen, John Carroll and Darren Pearce. 2000. Robust, Applied
     Morphological Generation. In Proceedings of the First International
     Natural Language Generation Conference (INLG), Mitzpe Ramon, Israel.
     201-208.

   The name of University of Sheffield may not be used to endorse or
   promote products derived from this software without specific prior
   written permission.
  
   This software is provided "as is" and without any express or
   implied warranties, including, without limitation, the implied
   warranties of merchantibility and fitness for a particular purpose.

   If you make any changes, the authors would appreciate it
   if you sent them details of what you have done.

   Covers the English productive affixes:

   -s	  plural of nouns, 3rd sing pres of verbs
   -ed	  past tense
   -en    past participle
   -ing	  progressive of verbs

   Compilation: flex -i -8 -Cfe -omorpha.yy.c morpha.lex
                gcc -o morpha morpha.yy.c
   CAVEAT: In order to be able to get the morphological analyser to return
   results immediately when used via unix pipes the flex and gcc command
   line options have to be adapted to:
                flex -i -omorpha.yy.c morpha.lex
                gcc -Dinteractive -o morpha morpha.yy.c

   Usage:       morpha [options:actuf verbstem-file] < file.txt 
   N.B. A file with a list of verb stems that allow for 
	consonant doubling in British English (called 'verbstem.list')
        is expected to be present in the same directory as morpha

   Options: a this option ensures that affixes are output. It is not
              relevant for the generator (morphg)
            c this option ensures that casing is left untouched
              wherever possible
            t this option ensures that tags are output; N.B. if
	      the option 'u' is set and the input text is tagged 
	      the tag will always be output even if this option 
	      is not set
            u this option should be used when the input file is 
	      untagged
            f a file with a list of verb stems that allow for
	      consonant doubling in British English (called
	      'verbstem.list') is expected
	      to be present in the same directory as morpha; using 
	      this option it is possible to specify a different file,
	      i.e., 'verbstem-file'

   Kevin Humphreys <kwh@dcs.shef.ac.uk> 
   original version: 30/03/95 - quick hack for LaSIE in the MUC6 dry-run
            revised: 06/12/95 - run stand-alone for Gerald Gazdar's use
            revised: 20/02/96 - for VIE, based on reports from Gerald Gazdar

   John Carroll <John.Carroll@cogs.susx.ac.uk>
            revised: 21/03/96 - made handling of -us and -use more accurate
	    revised: 26/06/96 - many more exceptions from corpora and MRDs

   Guido Minnen <Guido.Minnen@cogs.susx.ac.uk>
        revised: 03/12/98 - normal form and  different treatment of 
	                        consonant doubling introduced in order to 
				support automatic reversal; usage of 
				external list of verb 
				stems (derived from the BNC) that allow 
				for consonant doubling in British English
	                        introduced
	    revised: 19/05/99 - improvement of option handling
	    revised: 03/08/99 - introduction of option -f; adaption of 
	                        normal form to avoid the loss of case 
				information
	    revised: 01/09/99 - changed from normal form to compiler 
	                        directives format
	    revised: 06/10/99 - addition of the treatment of article
				and sentence initial markings,
				i.e. <ai> and <si> markings at the
				beginning of a word.  Modification of
				the scanning of the newline symbol
				such that no problems arise in
				interactive mode. Extension of the
				list of verbstems allowing for
				consonant doubling and incorporation
				of exception lists based on the CELEX
				lexical database.
	    revised: 02/12/99 - incorporated data extracted from the 
	 			CELEX lexical databases 
	    revised: 07/06/00 - adaption of Makefile to enable various 
	                        Flex optimizations

   John Carroll <John.Carroll@cogs.susx.ac.uk>
        revised: 25/01/01 - new version of inversion program,
                            associated changes to directives; new
                            C preprocessor flag 'interactive'

   Diana McCarthy <dianam@cogs.susx.ac.uk>
        revised: 23/02/02 - fixed bug reading in verbstem file.

   John Carroll <J.A.Carroll@sussex.ac.uk>
	    revised: 28/08/03 - fixes to -o(e) and -ff(e) words, a few
	            more irregulars, preferences for generating
	            alternative irregular forms.
                
   Exception lists are taken from WordNet 1.5, the CELEX lexical
   database (Copyright Centre for Lexical Information; Baayen,
   Piepenbrock and Van Rijn; 1993) and various other corpora and MRDs.

   Further exception lists are taken from the CELEX lexical database
   (Copyright Centre for Lexical Information; Baayen, Piepenbrock and
   Van Rijn; 1993).

   Many thanks to Tim Baldwin, Chris Brew, Bill Fisher, Gerald Gazdar,
   Dale Gerdemann, Adam Kilgarriff and Ehud Reiter for suggested
   improvements.

   WordNet> WordNet 1.5 Copyright 1995 by Princeton University.
   WordNet> All rights reseved.
   WordNet>
   WordNet> THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON
   WordNet> UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
   WordNet> IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON
   WordNet> UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-
   WordNet> ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE
   WordNet> OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
   WordNet> INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR
   WordNet> OTHER RIGHTS.
   WordNet>
   WordNet> The name of Princeton University or Princeton may not be used in
   WordNet> advertising or publicity pertaining to distribution of the software
   WordNet> and/or database.  Title to copyright in this software, database and
   WordNet> any associated documentation shall at all times remain with
   WordNet> Princeton Univerisy and LICENSEE agrees to preserve same.

  */

#include <string.h>

#ifdef interactive
#define YY_INPUT(buf,result,max_size) \
              { \
              int c = getchar(); \
              result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
              }
#define ECHO (void) fwrite( yytext, yyleng, 1, yyout ); fflush(yyout)
#endif

#define TRUE  (1==1)
#define FALSE  (1==0)
#define forever (TRUE)
#define UnSetOption(o)	(options.o = 0)
#define SetOption(o)	(options.o = 1)
#define Option(o)	(options.o)
#define MAXSTR    200
  /* #define YY_SKIP_YYWRAP */

#ifdef __cplusplus
char up8(char c);
int scmp(const char *a, const char *b);
int vcmp(const void *a, const void *b);
int in_verbstem_list(char *a);
void downcase( char *text, int len );
void capitalise( char *text, int len );
int stem(int eden,int dubbel, int del, const char *add, const char *affix,const char *root);
int condub_stem(int eden,int dubbel, int del, const char *add, const char *aff, const char *root);
int semi_reg_stem(int eden,int dubbel, int del, const char *add, const char *aff, const char *root);
int proper_name_stem();
int common_noun_stem();
int null_stem();
int xnull_stem();
int ynull_stem();
int cnull_stem();
char get_option(int argc, char *argv[], char *options, int *arg, int *i);
BOOL get_opt_string(char *argv[], char *result, unsigned int maxbuff, int *arg, int *i, char letter);
void set_up_options(int argc, char *argv[]); 
#endif

int lex_tag;

typedef struct
    {unsigned int
		print_affixes : 1,
		change_case   : 1,
                tag_output    : 1,
		fspec         : 1;
} options_st;
typedef int BOOL;

options_st options;
  /* int yywrap(); */
  /* int yywrap() { return(1); } */
int state;

%}

%option noyywrap

%x verb noun any scan

A ['+a-z0-9]
V [aeiou]
VY [aeiouy]
C [bcdfghjklmnpqrstvwxyz]
CXY [bcdfghjklmnpqrstvwxz]
CXY2 "bb"|"cc"|"dd"|"ff"|"gg"|"hh"|"jj"|"kk"|"ll"|"mm"|"nn"|"pp"|"qq"|"rr"|"ss"|"tt"|"vv"|"ww"|"xx"|"zz"
S2 "ss"|"zz"
S [sxz]|([cs]"h")
PRE "be"|"ex"|"in"|"mis"|"pre"|"pro"|"re"
EDING "ed"|"ing"
ESEDING "es"|"ed"|"ing"

G [^[:space:]_<>]
G- [^[:space:]_<>-]
SKIP [[:space:]]

%%

 /* can and will not always modal so can be inflected */
<verb,any>"shall"  { return(ynull_stem()); }
<verb,any>"would"  { return(ynull_stem()); }
<verb,any>"may"  { return(ynull_stem()); }
<verb,any>"might"  { return(ynull_stem()); }
<verb,any>"ought"  { return(ynull_stem()); }
<verb,any>"should"  { return(ynull_stem()); }
<verb,any>"am"  { return(stem(2,"be","")); }
<verb,any>"are"  { return(stem(3,"be","")); }             /* disprefer */
<verb,any>"is"  { return(stem(2,"be","s")); }           
<verb,any>"was"  { return(stem(3,"be","ed")); }
<verb,any>"wast"  { return(stem(4,"be","ed")); }          /* disprefer */
<verb,any>"wert"  { return(stem(4,"be","ed")); }          /* disprefer */
<verb,any>"were"  { return(stem(4,"be","ed")); }          /* disprefer */
<verb,any>"being"  { return(stem(5,"be","ing")); }        
<verb,any>"been"  { return(stem(4,"be","en")); }          
<verb,any>"had"  { return(stem(3,"have","ed")); }         /* en */
<verb,any>"has"  { return(stem(3,"have","s")); }          
<verb,any>"hath"  { return(stem(4,"have","s")); }         /* disprefer */
<verb,any>"does"  { return(stem(4,"do","s")); }            
<verb,any>"did"  { return(stem(3,"do","ed")); }          
<verb,any>"done"  { return(stem(4,"do","en")); }          
<verb,any>"didst"  { return(stem(5,"do","ed")); }         /* disprefer */
<verb,any>"'ll"  { return(stem(3,"will","")); }
<verb,any>"'m"  { return(stem(2,"be","")); }              /* disprefer */
<verb,any>"'re"  { return(stem(3,"be","")); }             /* disprefer */
<verb,any>"'ve"  { return(stem(3,"have","")); }

<verb,any>("beat"|"browbeat")"en"  { return(stem(2,"","en")); }
<verb,any>("beat"|"beset"|"bet"|"broadcast"|"browbeat"|"burst"|"cost"|"cut"|"hit"|"let"|"set"|"shed"|"shut"|"slit"|"split"|"put"|"quit"|"spread"|"sublet"|"spred"|"thrust"|"upset"|"hurt"|"bust"|"cast"|"forecast"|"inset"|"miscast"|"mishit"|"misread"|"offset"|"outbid"|"overbid"|"preset"|"read"|"recast"|"reset"|"telecast"|"typecast"|"typeset"|"underbid"|"undercut"|"wed"|"wet") { return(null_stem()); }
<verb,noun,any>"aches"  { return(stem(2,"e","s")); }     
<verb,any>"aped"    { return(stem(2,"e","ed")); }                  /* en */
<verb,any>"axed" { return(stem(2,"","ed")); }                      /* en */
<verb,any>("bias"|"canvas")"es"  { return(stem(2,"","s")); }
<verb,any>("cadd"|"v")"ied"  { return(stem(2,"e","ed")); }         /* en */
<verb,any>("cadd"|"v")"ying"  { return(stem(4,"ie","ing")); }     
<verb,noun,any>"cooees"  { return(stem(2,"e","s")); }
<verb,any>"cooeed"  { return(stem(3,"ee","ed")); }        /* en */
<verb,any>("ey"|"dy")"ed"  { return(stem(2,"e","ed")); }  /* en */
<verb,any>"eyeing"  { return(stem(3,"","ing")); }                 
<verb,any>"eying"  { return(stem(3,"e","ing")); }         /* disprefer */
<verb,any>"dying"  { return(stem(4,"ie","ing")); }       
<verb,any>("geld"|"gild")"ed"  { return(stem(2,"","ed")); }       
<verb,any>("outvi"|"hi")"ed"  { return(stem(2,"e","ed")); }  
<verb,any>"outlay"  { return(stem(2,"ie","ed")); }        /* en */
<verb,any>"rebound"  { return(stem(4,"ind","ed")); }      /* en */
<verb,any>"plummets"  { return(stem(1,"","s")); }                 
<verb,any>"queueing"  { return(stem(3,"","ing")); }               
<verb,any>"stomachs"  { return(stem(1,"","s")); }                 
<verb,any>"trammels"  { return(stem(1,"","s")); }                 
<verb,any>"tarmacked"  { return(stem(3,"","ed")); }       /* en */
<verb,any>"transfixed"  { return(stem(2,"","ed")); }      /* en */
<verb,any>"underlay"  { return(stem(2,"ie","ed")); }     
<verb,any>"overlay"  { return(stem(2,"ie","ed")); }      
<verb,any>"overflown"  { return(stem(3,"y","en")); }     
<verb,any>"relaid"  { return(stem(3,"ay","ed")); }        /* en */
<verb,any>"shat"  { return(stem(3,"hit","ed")); }         /* en */
<verb,any>"bereft"  { return(stem(3,"eave","ed")); }      /* en */
<verb,any>"clave"  { return(stem(3,"eave","ed")); }       /* en */ /* disprefer */
<verb,any>"wrought"  { return(stem(6,"ork","ed")); }      /* en */ /* disprefer */
<verb,any>"durst"  { return(stem(4,"are","ed")); }        /* en */ /* disprefer */
<verb,any>"foreswore"  { return(stem(3,"ear","ed")); }    /* en */
<verb,any>"outfought"  { return(stem(5,"ight","ed")); }   /* en */
<verb,any>"garotting"  { return(stem(3,"e","ing")); }     /* en */
<verb,any>"shorn"  { return(stem(3,"ear","en")); }
<verb,any>"spake"  { return(stem(3,"eak","ed")); }        /* en */ /* disprefer */
<verb,any>("analys"|"paralys"|"cach"|"brows"|"glimps"|"collaps"|"eclips"|"elaps"|"laps"|"traips"|"relaps"|"puls"|"repuls"|"cleans"|"rins"|"recompens"|"condens"|"dispens"|"incens"|"licens"|"sens"|"tens")"es" { return(stem(1,"","s")); }
<verb,any>"cached" { return(stem(2,"e","ed")); }         
<verb,any>"caching" { return(stem(3,"e","ing")); }       
<verb,any>("tun"|"gangren"|"wan"|"grip"|"unit"|"coher"|"comper"|"rever"|"semaphor"|"commun"|"reunit"|"dynamit"|"superven"|"telephon"|"ton"|"aton"|"bon"|"phon"|"plan"|"profan"|"importun"|"enthron"|"elop"|"interlop"|"sellotap"|"sideswip"|"slop"|"scrap"|"mop"|"lop"|"expung"|"lung"|"past"|"premier"|"rang"|"secret"){EDING} { return(semi_reg_stem(0,"e")); }
<verb,any>("unroll"|"unscroll"){EDING} { return(semi_reg_stem(0,"")); }
<verb,any>"unseat"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"whang"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>("bath"|"billet"|"collar"|"ballot"|"earth"|"fathom"|"fillet"|"mortar"|"parrot"|"profit"|"ransom"|"slang"){EDING} { return(semi_reg_stem(0,"")); }
<verb,any>("disunit"|"aquaplan"|"enplan"|"reveng"|"ripost"|"sein")"ed" { return(stem(2,"e","ed")); } /* en */
<verb,any>"toping" { return(stem(3,"e","ing")); }                  /* disprefer */
<verb,any>("disti"|"fulfi"|"appa")"lls" { return(stem(2,"","s")); }
<verb,any>("overca"|"misca")"lled" { return(stem(2,"","ed")); }   
<verb,any>"catcalling" { return(stem(3,"","ing")); }              
<verb,any>("catcall"|"squall")"ing" { return(stem(3,"","ing")); } 
<verb,any>("browbeat"|"ax"|"dubbin")"ing" { return(stem(3,"","ing")); }
<verb,any>"summonses" { return(stem(2,"","s")); }        
<verb,any>"putted" { return(stem(2,"","ed")); }          
<verb,any>"summonsed" { return(stem(2,"","ed")); }       
<verb,any>("sugar"|"tarmacadam"|"beggar"|"betroth"|"boomerang"|"chagrin"|"envenom"|"miaou"|"pressgang")"ed" { return(stem(2,"","ed")); }
<verb,any>"abode"  { return(stem(3,"ide","ed")); }        /* en */
<verb,any>"abought"  { return(stem(5,"y","ed")); }        /* en */
<verb,any>"abyes"  { return(stem(2,"","s")); }           
<verb,any>"addrest"  { return(stem(3,"ess","ed")); }      /* en */ /* disprefer */
<verb,any>"ageing"  { return(stem(4,"e","ing")); }       
<verb,any>"agreed"  { return(stem(3,"ee","ed")); }        /* en */
<verb,any>"anted"  { return(stem(3,"te","ed")); }         /* en */
<verb,any>"antes"  { return(stem(2,"e","s")); }          
<verb,any>"arisen"  { return(stem(3,"se","en")); }       
<verb,any>"arose"  { return(stem(3,"ise","ed")); }       
<verb,any>"ate"  { return(stem(3,"eat","ed")); }         
<verb,any>"awoke"  { return(stem(3,"ake","ed")); }       
<verb,any>"awoken"  { return(stem(4,"ake","en")); }      
<verb,any>"backbit"  { return(stem(3,"bite","ed")); }    
<verb,any>"backbiting"  { return(stem(4,"te","ing")); }  
<verb,any>"backbitten"  { return(stem(3,"e","en")); }    
<verb,any>"backslid"  { return(stem(3,"lide","ed")); }   
<verb,any>"backslidden"  { return(stem(3,"e","en")); }   
<verb,any>"bad"  { return(stem(3,"bid","ed")); }          /* disprefer */
<verb,any>"bade"  { return(stem(3,"id","ed")); }         
<verb,any>"bandieds"  { return(stem(4,"y","s")); }       
<verb,any>"became"  { return(stem(3,"ome","ed")); }       /* en */
<verb,any>"befallen"  { return(stem(3,"l","en")); }      
<verb,any>"befalling"  { return(stem(4,"l","ing")); }    
<verb,any>"befell"  { return(stem(3,"all","ed")); }      
<verb,any>"began"  { return(stem(3,"gin","ed")); }       
<verb,any>"begat"  { return(stem(3,"get","ed")); }        /* disprefer */       
<verb,any>"begirt"  { return(stem(3,"ird","ed")); }       /* en */
<verb,any>"begot"  { return(stem(3,"get","ed")); }
<verb,any>"begotten"  { return(stem(5,"et","en")); }     
<verb,any>"begun"  { return(stem(3,"gin","en")); }       
<verb,any>"beheld"  { return(stem(3,"old","ed")); }      
<verb,any>"beholden"  { return(stem(3,"d","en")); }      
<verb,any>"benempt"  { return(stem(4,"ame","ed")); }      /* en */
<verb,any>"bent"  { return(stem(3,"end","ed")); }         /* en */
<verb,any>"besought"  { return(stem(5,"eech","ed")); }    /* en */
<verb,any>"bespoke"  { return(stem(3,"eak","ed")); }     
<verb,any>"bespoken"  { return(stem(4,"eak","en")); }    
<verb,any>"bestrewn"  { return(stem(3,"ew","en")); }     
<verb,any>"bestrid"  { return(stem(3,"ride","ed")); }     /* disprefer */
<verb,any>"bestridden"  { return(stem(3,"e","en")); }    
<verb,any>"bestrode"  { return(stem(3,"ide","ed")); }    
<verb,any>"betaken"  { return(stem(3,"ke","en")); }      
<verb,any>"bethought"  { return(stem(5,"ink","ed")); }    /* en */
<verb,any>"betook"  { return(stem(3,"ake","ed")); }      
<verb,any>"bidden"  { return(stem(3,"","en")); }         
<verb,any>"bit"  { return(stem(3,"bite","ed")); }        
<verb,any>"biting"  { return(stem(4,"te","ing")); }      
<verb,any>"bitten"  { return(stem(3,"e","en")); }        
<verb,any>"bled"  { return(stem(3,"leed","ed")); }        /* en */
<verb,any>"blest"  { return(stem(3,"ess","ed")); }        /* en */ /* disprefer */
<verb,any>"blew"  { return(stem(3,"low","ed")); }        
<verb,any>"blown"  { return(stem(3,"ow","en")); }        
<verb,any>"bogged-down"  { return(stem(8,"-down","ed")); } /* en */
<verb,any>"bogging-down"  { return(stem(9,"-down","ing")); }
<verb,any>"bogs-down"  { return(stem(6,"-down","s")); }  
<verb,any>"boogied"  { return(stem(3,"ie","ed")); }       /* en */
<verb,any>"boogies"  { return(stem(2,"e","s")); }        
<verb,any>"bore"  { return(stem(3,"ear","ed")); }        
<verb,any>"borne"  { return(stem(4,"ear","en")); }        /* disprefer */
<verb,any>"born"  { return(stem(3,"ear","en")); }        
<verb,any>"bought"  { return(stem(5,"uy","ed")); }        /* en */
<verb,any>"bound"  { return(stem(4,"ind","ed")); }        /* en */
<verb,any>"breastfed"  { return(stem(3,"feed","ed")); }   /* en */
<verb,any>"bred"  { return(stem(3,"reed","ed")); }        /* en */
<verb,any>"breid"  { return(stem(3,"ei","ed")); }         /* en */
<verb,any>"bringing"  { return(stem(4,"g","ing")); }     
<verb,any>"broke"  { return(stem(3,"eak","ed")); }       
<verb,any>"broken"  { return(stem(4,"eak","en")); }      
<verb,any>"brought"  { return(stem(5,"ing","ed")); }      /* en */
<verb,any>"built"  { return(stem(3,"ild","ed")); }        /* en */
<verb,any>"burnt"  { return(stem(3,"rn","ed")); }         /* en */ /* disprefer */
<verb,any>"bypast"  { return(stem(3,"ass","ed")); }       /* en */ /* disprefer */
<verb,any>"came"  { return(stem(3,"ome","ed")); }         /* en */
<verb,any>"caught"  { return(stem(4,"tch","ed")); }       /* en */
<verb,any>"chassed"  { return(stem(3,"se","ed")); }       /* en */
<verb,any>"chasseing"  { return(stem(4,"e","ing")); }    
<verb,any>"chasses"  { return(stem(2,"e","s")); }        
<verb,any>"chevied"  { return(stem(5,"ivy","ed")); }      /* en */ /* disprefer */
<verb,any>"chevies"  { return(stem(5,"ivy","s")); }       /* disprefer */
<verb,any>"chevying"  { return(stem(6,"ivy","ing")); }    /* disprefer */
<verb,any>"chid"  { return(stem(3,"hide","ed")); }        /* disprefer */
<verb,any>"chidden"  { return(stem(3,"e","en")); }        /* disprefer */
<verb,any>"chivvied"  { return(stem(4,"y","ed")); }       /* en */
<verb,any>"chivvies"  { return(stem(4,"y","s")); }       
<verb,any>"chivvying"  { return(stem(5,"y","ing")); }    
<verb,any>"chose"  { return(stem(3,"oose","ed")); }      
<verb,any>"chosen"  { return(stem(3,"ose","en")); }      
<verb,any>"clad"  { return(stem(3,"lothe","ed")); }       /* en */
<verb,any>"cleft"  { return(stem(3,"eave","ed")); }       /* en */ /* disprefer */
<verb,any>"clept"  { return(stem(3,"epe","ed")); }        /* en */ /* disprefer */
<verb,any>"clinging"  { return(stem(4,"g","ing")); }     
<verb,any>"clove"  { return(stem(3,"eave","ed")); }      
<verb,any>"cloven"  { return(stem(4,"eave","en")); }     
<verb,any>"clung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"countersank"  { return(stem(3,"ink","ed")); } 
<verb,any>"countersunk"  { return(stem(3,"ink","en")); } 
<verb,any>"crept"  { return(stem(3,"eep","ed")); }        /* en */
<verb,any>"crossbred"  { return(stem(3,"reed","ed")); }   /* en */
<verb,any>"curettes"  { return(stem(3,"","s")); }        
<verb,any>"curst"  { return(stem(3,"rse","ed")); }        /* en */ /* disprefer */
<verb,any>"dealt"  { return(stem(3,"al","ed")); }         /* en */
<verb,any>"decreed"  { return(stem(3,"ee","ed")); }       /* en */
<verb,any>"degases"  { return(stem(2,"","s")); }         
<verb,any>"deleing"  { return(stem(4,"e","ing")); }      
<verb,any>"disagreed"  { return(stem(3,"ee","ed")); }     /* en */
<verb,any>"disenthralls"  { return(stem(2,"","s")); }     /* disprefer */
<verb,any>"disenthrals"  { return(stem(2,"l","s")); }    
<verb,any>"dought"  { return(stem(4,"w","ed")); }         /* en */
<verb,any>"dove"  { return(stem(3,"ive","ed")); }         /* en */ /* disprefer */
<verb,any>"drank"  { return(stem(3,"ink","ed")); }       
<verb,any>"drawn"  { return(stem(3,"aw","en")); }        
<verb,any>"dreamt"  { return(stem(3,"am","ed")); }        /* en */
<verb,any>"dreed"  { return(stem(3,"ee","ed")); }         /* en */
<verb,any>"drew"  { return(stem(3,"raw","ed")); }        
<verb,any>"driven"  { return(stem(3,"ve","en")); }       
<verb,any>"drove"  { return(stem(3,"ive","ed")); }       
<verb,any>"drunk"  { return(stem(3,"ink","en")); }       
<verb,any>"dug"  { return(stem(3,"dig","ed")); }          /* en */
<verb,any>"dwelt"  { return(stem(3,"ell","ed")); }        /* en */
<verb,any>"eaten"  { return(stem(3,"t","en")); }         
<verb,any>"emceed"  { return(stem(3,"ee","ed")); }        /* en */
<verb,any>"enwound"  { return(stem(4,"ind","ed")); }      /* en */
<verb,any>"facsimileing"  { return(stem(4,"e","ing")); } 
<verb,any>"fallen"  { return(stem(3,"l","en")); }        
<verb,any>"fed"  { return(stem(3,"feed","ed")); }         /* en */
<verb,any>"fell"  { return(stem(3,"all","ed")); }        
<verb,any>"felt"  { return(stem(3,"eel","ed")); }         /* en */
<verb,any>"filagreed"  { return(stem(3,"ee","ed")); }     /* en */
<verb,any>"filigreed"  { return(stem(3,"ee","ed")); }     /* en */
<verb,any>"fillagreed"  { return(stem(3,"ee","ed")); }    /* en */
<verb,any>"fled"  { return(stem(3,"lee","ed")); }         /* en */
<verb,any>"flew"  { return(stem(3,"ly","ed")); }         
<verb,any>"flinging"  { return(stem(4,"g","ing")); }     
<verb,any>"floodlit"  { return(stem(3,"light","ed")); }   /* en */
<verb,any>"flown"  { return(stem(3,"y","en")); }         
<verb,any>"flung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"flyblew"  { return(stem(3,"low","ed")); }     
<verb,any>"flyblown"  { return(stem(3,"ow","en")); }     
<verb,any>"forbade"  { return(stem(3,"id","ed")); }
<verb,any>"forbad"  { return(stem(3,"bid","ed")); }       /* disprefer */
<verb,any>"forbidden"  { return(stem(3,"","en")); }      
<verb,any>"forbore"  { return(stem(3,"ear","ed")); }     
<verb,any>"forborne"  { return(stem(4,"ear","en")); }    
<verb,any>"fordid"  { return(stem(3,"do","ed")); }       
<verb,any>"fordone"  { return(stem(3,"o","en")); }       
<verb,any>"foredid"  { return(stem(3,"do","ed")); }      
<verb,any>"foredone"  { return(stem(3,"o","en")); }      
<verb,any>"foregone"  { return(stem(3,"o","en")); }      
<verb,any>"foreknew"  { return(stem(3,"now","ed")); }    
<verb,any>"foreknown"  { return(stem(3,"ow","en")); }    
<verb,any>"foreran"  { return(stem(3,"run","ed")); }      /* en */
<verb,any>"foresaw"  { return(stem(3,"see","ed")); }     
<verb,any>"foreseen"  { return(stem(3,"ee","en")); }     
<verb,any>"foreshown"  { return(stem(3,"ow","en")); }    
<verb,any>"forespoke"  { return(stem(3,"eak","ed")); }   
<verb,any>"forespoken"  { return(stem(4,"eak","en")); }  
<verb,any>"foretelling"  { return(stem(4,"l","ing")); }  
<verb,any>"foretold"  { return(stem(3,"ell","ed")); }     /* en */
<verb,any>"forewent"  { return(stem(4,"go","ed")); }     
<verb,any>"forgave"  { return(stem(3,"ive","ed")); }     
<verb,any>"forgiven"  { return(stem(3,"ve","en")); }     
<verb,any>"forgone"  { return(stem(3,"o","en")); }       
<verb,any>"forgot"  { return(stem(3,"get","ed")); }      
<verb,any>"forgotten"  { return(stem(5,"et","en")); }    
<verb,any>"forsaken"  { return(stem(3,"ke","en")); }     
<verb,any>"forsook"  { return(stem(3,"ake","ed")); }     
<verb,any>"forspoke"  { return(stem(3,"eak","ed")); }    
<verb,any>"forspoken"  { return(stem(4,"eak","en")); }   
<verb,any>"forswore"  { return(stem(3,"ear","ed")); }    
<verb,any>"forsworn"  { return(stem(3,"ear","en")); }    
<verb,any>"forwent"  { return(stem(4,"go","ed")); }      
<verb,any>"fought"  { return(stem(5,"ight","ed")); }      /* en */
<verb,any>"found"  { return(stem(4,"ind","ed")); }        /* en */
<verb,any>"freed"  { return(stem(3,"ee","ed")); }         /* en */
<verb,any>"fricasseed"  { return(stem(3,"ee","ed")); }    /* en */
<verb,any>"froze"  { return(stem(3,"eeze","ed")); }      
<verb,any>"frozen"  { return(stem(4,"eeze","en")); }     
<verb,any>"gainsaid"  { return(stem(3,"ay","ed")); }      /* en */
<verb,any>"gan"  { return(stem(3,"gin","en")); }         
<verb,any>"garnisheed"  { return(stem(3,"ee","ed")); }    /* en */
<verb,any>"gases"  { return(stem(2,"","s")); }           
<verb,any>"gave"  { return(stem(3,"ive","ed")); }        
<verb,any>"geed"  { return(stem(3,"ee","ed")); }          /* en */
<verb,any>"gelt"  { return(stem(3,"eld","ed")); }         /* en */
<verb,any>"genned-up"  { return(stem(6,"-up","ed")); }    /* en */
<verb,any>"genning-up"  { return(stem(7,"-up","ing")); } 
<verb,any>"gens-up"  { return(stem(4,"-up","s")); }      
<verb,any>"ghostwriting"  { return(stem(4,"te","ing")); }
<verb,any>"ghostwritten"  { return(stem(3,"e","en")); }  
<verb,any>"ghostwrote"  { return(stem(3,"ite","ed")); }  
<verb,any>"gilt"  { return(stem(3,"ild","ed")); }         /* en */ /* disprefer */
<verb,any>"girt"  { return(stem(3,"ird","ed")); }         /* en */ /* disprefer */
<verb,any>"given"  { return(stem(3,"ve","en")); }        
<verb,any>"gnawn"  { return(stem(3,"aw","en")); }        
<verb,any>"gone"  { return(stem(3,"o","en")); }          
<verb,any>"got"  { return(stem(3,"get","ed")); }         
<verb,any>"gotten"  { return(stem(5,"et","en")); }       
<verb,any>"graven"  { return(stem(3,"ve","en")); }       
<verb,any>"greed"  { return(stem(3,"ee","ed")); }         /* en */
<verb,any>"grew"  { return(stem(3,"row","ed")); }        
<verb,any>"gript"  { return(stem(3,"ip","ed")); }         /* en */ /* disprefer */
<verb,any>"ground"  { return(stem(4,"ind","ed")); }       /* en */
<verb,any>"grown"  { return(stem(3,"ow","en")); }        
<verb,any>"guaranteed"  { return(stem(3,"ee","ed")); }    /* en */
<verb,any>"hacksawn"  { return(stem(3,"aw","en")); }     
<verb,any>"hamstringing"  { return(stem(4,"g","ing")); } 
<verb,any>"hamstrung"  { return(stem(3,"ing","ed")); }    /* en */
<verb,any>"handfed"  { return(stem(3,"feed","ed")); }     /* en */
<verb,any>"heard"  { return(stem(3,"ar","ed")); }         /* en */
<verb,any>"held"  { return(stem(3,"old","ed")); }         /* en */
<verb,any>"hewn"  { return(stem(3,"ew","en")); }         
<verb,any>"hid"  { return(stem(3,"hide","ed")); }        
<verb,any>"hidden"  { return(stem(3,"e","en")); }        
<verb,any>"honied"  { return(stem(3,"ey","ed")); }        /* en */
<verb,any>"hove"  { return(stem(3,"eave","ed")); }        /* en */ /* disprefer */
<verb,any>"hung"  { return(stem(3,"ang","ed")); }         /* en */
<verb,any>"impanells"  { return(stem(2,"","s")); }       
<verb,any>"inbred"  { return(stem(3,"reed","ed")); }      /* en */
<verb,any>"indwelling"  { return(stem(4,"l","ing")); }   
<verb,any>"indwelt"  { return(stem(3,"ell","ed")); }      /* en */
<verb,any>"inlaid"  { return(stem(3,"ay","ed")); }        /* en */
<verb,any>"interbred"  { return(stem(3,"reed","ed")); }   /* en */
<verb,any>"interlaid"  { return(stem(3,"ay","ed")); }     /* en */
<verb,any>"interpled"  { return(stem(3,"lead","ed")); }   /* en */ /* disprefer */
<verb,any>"interwove"  { return(stem(3,"eave","ed")); }  
<verb,any>"interwoven"  { return(stem(4,"eave","en")); } 
<verb,any>"inwove"  { return(stem(3,"eave","ed")); }     
<verb,any>"inwoven"  { return(stem(4,"eave","en")); }    
<verb,any>"joint"  { return(stem(3,"in","ed")); }         /* en */ /* disprefer */
<verb,any>"kent"  { return(stem(3,"en","ed")); }          /* en */
<verb,any>"kept"  { return(stem(3,"eep","ed")); }         /* en */
<verb,any>"kneed"  { return(stem(3,"ee","ed")); }         /* en */
<verb,any>"knelt"  { return(stem(3,"eel","ed")); }        /* en */
<verb,any>"knew"  { return(stem(3,"now","ed")); }        
<verb,any>"known"  { return(stem(3,"ow","en")); }        
<verb,any>"laden"  { return(stem(3,"de","en")); }        
<verb,any>"ladyfied"  { return(stem(5,"ify","ed")); }     /* en */
<verb,any>"ladyfies"  { return(stem(5,"ify","s")); }     
<verb,any>"ladyfying"  { return(stem(6,"ify","ing")); }  
<verb,any>"laid"  { return(stem(3,"ay","ed")); }          /* en */
<verb,any>"lain"  { return(stem(3,"ie","en")); }         
<verb,any>"leant"  { return(stem(3,"an","ed")); }         /* en */ /* disprefer */
<verb,any>"leapt"  { return(stem(3,"ap","ed")); }         /* en */
<verb,any>"learnt"  { return(stem(3,"rn","ed")); }        /* en */
<verb,any>"led"  { return(stem(3,"lead","ed")); }         /* en */
<verb,any>"left"  { return(stem(3,"eave","ed")); }        /* en */
<verb,any>"lent"  { return(stem(3,"end","ed")); }         /* en */
<verb,any>"lit"  { return(stem(3,"light","ed")); }        /* en */
<verb,any>"lost"  { return(stem(3,"ose","ed")); }         /* en */
<verb,any>"made"  { return(stem(3,"ake","ed")); }         /* en */
<verb,any>"meant"  { return(stem(3,"an","ed")); }         /* en */
<verb,any>"met"  { return(stem(3,"meet","ed")); }         /* en */
<verb,any>"misbecame"  { return(stem(3,"ome","ed")); }    /* en */
<verb,any>"misdealt"  { return(stem(3,"al","ed")); }      /* en */
<verb,any>"misgave"  { return(stem(3,"ive","ed")); }     
<verb,any>"misgiven"  { return(stem(3,"ve","en")); }     
<verb,any>"misheard"  { return(stem(3,"ar","ed")); }      /* en */
<verb,any>"mislaid"  { return(stem(3,"ay","ed")); }       /* en */
<verb,any>"misled"  { return(stem(3,"lead","ed")); }      /* en */
<verb,any>"mispled"  { return(stem(3,"lead","ed")); }     /* en */ /* disprefer */
<verb,any>"misspelt"  { return(stem(3,"ell","ed")); }     /* en */ /* disprefer */
<verb,any>"misspent"  { return(stem(3,"end","ed")); }     /* en */
<verb,any>"mistaken"  { return(stem(3,"ke","en")); }     
<verb,any>"mistook"  { return(stem(3,"ake","ed")); }      /* en */
<verb,any>"misunderstood"  { return(stem(3,"and","ed")); } /* en */
<verb,any>"molten"  { return(stem(5,"elt","en")); }      
<verb,any>"mown"  { return(stem(3,"ow","en")); }         
<verb,any>"outbidden"  { return(stem(3,"","en")); }       /* disprefer */
<verb,any>"outbred"  { return(stem(3,"reed","ed")); }     /* en */
<verb,any>"outdid"  { return(stem(3,"do","ed")); }       
<verb,any>"outdone"  { return(stem(3,"o","en")); }       
<verb,any>"outgone"  { return(stem(3,"o","en")); }       
<verb,any>"outgrew"  { return(stem(3,"row","ed")); }     
<verb,any>"outgrown"  { return(stem(3,"ow","en")); }     
<verb,any>"outlaid"  { return(stem(3,"ay","ed")); }       /* en */
<verb,any>"outran"  { return(stem(3,"run","ed")); }       /* en */
<verb,any>"outridden"  { return(stem(3,"e","en")); }     
<verb,any>"outrode"  { return(stem(3,"ide","ed")); }     
<verb,any>"outselling"  { return(stem(4,"l","ing")); }   
<verb,any>"outshone"  { return(stem(3,"ine","ed")); }     /* en */
<verb,any>"outshot"  { return(stem(3,"hoot","ed")); }     /* en */
<verb,any>"outsold"  { return(stem(3,"ell","ed")); }      /* en */
<verb,any>"outstood"  { return(stem(3,"and","ed")); }     /* en */
<verb,any>"outthought"  { return(stem(5,"ink","ed")); }   /* en */
<verb,any>"outwent"  { return(stem(4,"go","ed")); }       /* en */
<verb,any>"outwore"  { return(stem(3,"ear","ed")); }     
<verb,any>"outworn"  { return(stem(3,"ear","en")); }     
<verb,any>"overbidden"  { return(stem(3,"","en")); }      /* disprefer */
<verb,any>"overblew"  { return(stem(3,"low","ed")); }    
<verb,any>"overblown"  { return(stem(3,"ow","en")); }    
<verb,any>"overbore"  { return(stem(3,"ear","ed")); }    
<verb,any>"overborne"  { return(stem(4,"ear","en")); }   
<verb,any>"overbuilt"  { return(stem(3,"ild","ed")); }    /* en */
<verb,any>"overcame"  { return(stem(3,"ome","ed")); }     /* en */
<verb,any>"overdid"  { return(stem(3,"do","ed")); }      
<verb,any>"overdone"  { return(stem(3,"o","en")); }      
<verb,any>"overdrawn"  { return(stem(3,"aw","en")); }    
<verb,any>"overdrew"  { return(stem(3,"raw","ed")); }    
<verb,any>"overdriven"  { return(stem(3,"ve","en")); }   
<verb,any>"overdrove"  { return(stem(3,"ive","ed")); }   
<verb,any>"overflew"  { return(stem(3,"ly","ed")); }      /* en */
<verb,any>"overgrew"  { return(stem(3,"row","ed")); }    
<verb,any>"overgrown"  { return(stem(3,"ow","en")); }    
<verb,any>"overhanging"  { return(stem(4,"g","ing")); }  
<verb,any>"overheard"  { return(stem(3,"ar","ed")); }     /* en */
<verb,any>"overhung"  { return(stem(3,"ang","ed")); }     /* en */
<verb,any>"overlaid"  { return(stem(3,"ay","ed")); }      /* en */
<verb,any>"overlain"  { return(stem(3,"ie","en")); }     
<verb,any>"overlies"  { return(stem(2,"e","s")); }       
<verb,any>"overlying"  { return(stem(4,"ie","ing")); }   
<verb,any>"overpaid"  { return(stem(3,"ay","ed")); }      /* en */
<verb,any>"overpast"  { return(stem(3,"ass","ed")); }     /* en */
<verb,any>"overran"  { return(stem(3,"run","ed")); }      /* en */
<verb,any>"overridden"  { return(stem(3,"e","en")); }    
<verb,any>"overrode"  { return(stem(3,"ide","ed")); }    
<verb,any>"oversaw"  { return(stem(3,"see","ed")); }     
<verb,any>"overseen"  { return(stem(3,"ee","en")); }     
<verb,any>"overselling"  { return(stem(4,"l","ing")); }  
<verb,any>"oversewn"  { return(stem(3,"ew","en")); }     
<verb,any>"overshot"  { return(stem(3,"hoot","ed")); }    /* en */
<verb,any>"overslept"  { return(stem(3,"eep","ed")); }    /* en */
<verb,any>"oversold"  { return(stem(3,"ell","ed")); }     /* en */
<verb,any>"overspent"  { return(stem(3,"end","ed")); }    /* en */
<verb,any>"overspilt"  { return(stem(3,"ill","ed")); }    /* en */ /* disprefer */
<verb,any>"overtaken"  { return(stem(3,"ke","en")); }    
<verb,any>"overthrew"  { return(stem(3,"row","ed")); }   
<verb,any>"overthrown"  { return(stem(3,"ow","en")); }   
<verb,any>"overtook"  { return(stem(3,"ake","ed")); }    
<verb,any>"overwound"  { return(stem(4,"ind","ed")); }    /* en */
<verb,any>"overwriting"  { return(stem(4,"te","ing")); } 
<verb,any>"overwritten"  { return(stem(3,"e","en")); }   
<verb,any>"overwrote"  { return(stem(3,"ite","ed")); }   
<verb,any>"paid"  { return(stem(3,"ay","ed")); }          /* en */
<verb,any>"partaken"  { return(stem(3,"ke","en")); }     
<verb,any>"partook"  { return(stem(3,"ake","ed")); }     
<verb,any>"peed"  { return(stem(3,"ee","ed")); }          /* en */
<verb,any>"pent"  { return(stem(3,"en","ed")); }          /* en */ /* disprefer */
<verb,any>"pled"  { return(stem(3,"lead","ed")); }        /* en */ /* disprefer */
<verb,any>"prepaid"  { return(stem(3,"ay","ed")); }       /* en */
<verb,any>"prologs"  { return(stem(2,"gue","s")); }      
<verb,any>"proven"  { return(stem(3,"ve","en")); }       
<verb,any>"pureed"  { return(stem(3,"ee","ed")); }        /* en */
<verb,any>"quartersawn"  { return(stem(3,"aw","en")); }  
<verb,any>"queued"  { return(stem(3,"ue","ed")); }        /* en */
<verb,any>"queues"  { return(stem(2,"e","s")); }         
<verb,any>"queuing"  { return(stem(4,"ue","ing")); }      /* disprefer */
<verb,any>"ran"  { return(stem(3,"run","ed")); }          /* en */
<verb,any>"rang"  { return(stem(3,"ing","ed")); }        
<verb,any>"rarefied"  { return(stem(3,"y","ed")); }       /* en */
<verb,any>"rarefies"  { return(stem(3,"y","s")); }       
<verb,any>"rarefying"  { return(stem(4,"y","ing")); }    
<verb,any>"razeed"  { return(stem(3,"ee","ed")); }       
<verb,any>"rebuilt"  { return(stem(3,"ild","ed")); }      /* en */
<verb,any>"recced"  { return(stem(3,"ce","ed")); }        /* en */
<verb,any>"red"  { return(stem(3,"red","ed")); }          /* en */
<verb,any>"redid"  { return(stem(3,"do","ed")); }        
<verb,any>"redone"  { return(stem(3,"o","en")); }        
<verb,any>"refereed"  { return(stem(3,"ee","ed")); }      /* en */
<verb,any>"reft"  { return(stem(3,"eave","ed")); }        /* en */
<verb,any>"remade"  { return(stem(3,"ake","ed")); }       /* en */
<verb,any>"repaid"  { return(stem(3,"ay","ed")); }        /* en */
<verb,any>"reran"  { return(stem(3,"run","ed")); }        /* en */
<verb,any>"resat"  { return(stem(3,"sit","ed")); }        /* en */
<verb,any>"retaken"  { return(stem(3,"ke","en")); }      
<verb,any>"rethought"  { return(stem(5,"ink","ed")); }    /* en */
<verb,any>"retook"  { return(stem(3,"ake","ed")); }      
<verb,any>"rewound"  { return(stem(4,"ind","ed")); }      /* en */
<verb,any>"rewriting"  { return(stem(4,"te","ing")); }   
<verb,any>"rewritten"  { return(stem(3,"e","en")); }     
<verb,any>"rewrote"  { return(stem(3,"ite","ed")); }     
<verb,any>"ridden"  { return(stem(3,"e","en")); }        
<verb,any>"risen"  { return(stem(3,"se","en")); }        
<verb,any>"riven"  { return(stem(3,"ve","en")); }        
<verb,any>"rode"  { return(stem(3,"ide","ed")); }        
<verb,any>"rose"  { return(stem(3,"ise","ed")); }        
<verb,any>"rove"  { return(stem(3,"eeve","ed")); }        /* en */
<verb,any>"rung"  { return(stem(3,"ing","en")); }        
<verb,any>"said"  { return(stem(3,"ay","ed")); }          /* en */
<verb,any>"sang"  { return(stem(3,"ing","ed")); }        
<verb,any>"sank"  { return(stem(3,"ink","ed")); }        
<verb,any>"sat"  { return(stem(3,"sit","ed")); }          /* en */
<verb,any>"saw"  { return(stem(3,"see","ed")); }         
<verb,any>"sawn"  { return(stem(3,"aw","en")); }         
<verb,any>"seen"  { return(stem(3,"ee","en")); }         
<verb,any>"sent"  { return(stem(3,"end","ed")); }         /* en */
<verb,any>"sewn"  { return(stem(3,"ew","en")); }         
<verb,any>"shaken"  { return(stem(3,"ke","en")); }       
<verb,any>"shaven"  { return(stem(3,"ve","en")); }       
<verb,any>"shent"  { return(stem(3,"end","ed")); }        /* en */
<verb,any>"shewn"  { return(stem(3,"ew","en")); }        
<verb,any>"shod"  { return(stem(3,"hoe","ed")); }         /* en */
<verb,any>"shone"  { return(stem(3,"ine","ed")); }        /* en */
<verb,any>"shook"  { return(stem(3,"ake","ed")); }       
<verb,any>"shot"  { return(stem(3,"hoot","ed")); }        /* en */
<verb,any>"shown"  { return(stem(3,"ow","en")); }        
<verb,any>"shrank"  { return(stem(3,"ink","ed")); }      
<verb,any>"shriven"  { return(stem(3,"ve","en")); }      
<verb,any>"shrove"  { return(stem(3,"ive","ed")); }      
<verb,any>"shrunk"  { return(stem(3,"ink","en")); }      
<verb,any>"shrunken"  { return(stem(5,"ink","en")); }     /* disprefer */
<verb,any>"sightsaw"  { return(stem(3,"see","ed")); }    
<verb,any>"sightseen"  { return(stem(3,"ee","en")); }    
<verb,any>"ski'd"  { return(stem(3,"i","ed")); }          /* en */
<verb,any>"skydove"  { return(stem(3,"ive","ed")); }      /* en */
<verb,any>"slain"  { return(stem(3,"ay","en")); }        
<verb,any>"slept"  { return(stem(3,"eep","ed")); }        /* en */
<verb,any>"slew"  { return(stem(3,"lay","ed")); }        
<verb,any>"slid"  { return(stem(3,"lide","ed")); }       
<verb,any>"slidden"  { return(stem(3,"e","en")); }       
<verb,any>"slinging"  { return(stem(4,"g","ing")); }     
<verb,any>"slung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"slunk"  { return(stem(3,"ink","ed")); }        /* en */
<verb,any>"smelt"  { return(stem(3,"ell","ed")); }        /* en */ /* disprefer */
<verb,any>"smit"  { return(stem(3,"mite","ed")); }       
<verb,any>"smiting"  { return(stem(4,"te","ing")); }     
<verb,any>"smitten"  { return(stem(3,"e","en")); }       
<verb,any>"smote"  { return(stem(3,"ite","ed")); }        /* en */ /* disprefer */
<verb,any>"sold"  { return(stem(3,"ell","ed")); }         /* en */
<verb,any>"soothsaid"  { return(stem(3,"ay","ed")); }     /* en */
<verb,any>"sortied"  { return(stem(3,"ie","ed")); }       /* en */
<verb,any>"sorties"  { return(stem(2,"e","s")); }        
<verb,any>"sought"  { return(stem(5,"eek","ed")); }       /* en */
<verb,any>"sown"  { return(stem(3,"ow","en")); }         
<verb,any>"spat"  { return(stem(3,"pit","ed")); }         /* en */
<verb,any>"sped"  { return(stem(3,"peed","ed")); }        /* en */
<verb,any>"spellbound"  { return(stem(4,"ind","ed")); }   /* en */
<verb,any>"spelt"  { return(stem(3,"ell","ed")); }        /* en */ /* disprefer */
<verb,any>"spent"  { return(stem(3,"end","ed")); }        /* en */
<verb,any>"spilt"  { return(stem(3,"ill","ed")); }        /* en */ /* disprefer */
<verb,any>"spoilt"  { return(stem(3,"il","ed")); }        /* en */
<verb,any>"spoke"  { return(stem(3,"eak","ed")); }       
<verb,any>"spoken"  { return(stem(4,"eak","en")); }      
<verb,any>"spotlit"  { return(stem(3,"light","ed")); }    /* en */
<verb,any>"sprang"  { return(stem(3,"ing","ed")); }      
<verb,any>"springing"  { return(stem(4,"g","ing")); }    
<verb,any>"sprung"  { return(stem(3,"ing","en")); }      
<verb,any>"spun"  { return(stem(3,"pin","ed")); }         /* en */
<verb,any>"squeegeed"  { return(stem(3,"ee","ed")); }     /* en */
<verb,any>"stank"  { return(stem(3,"ink","ed")); }       
<verb,any>"stinging"  { return(stem(4,"g","ing")); }     
<verb,any>"stole"  { return(stem(3,"eal","ed")); }       
<verb,any>"stolen"  { return(stem(4,"eal","en")); }      
<verb,any>"stood"  { return(stem(3,"and","ed")); }        /* en */
<verb,any>"stove"  { return(stem(3,"ave","ed")); }        /* en */
<verb,any>"strewn"  { return(stem(3,"ew","en")); }       
<verb,any>"stridden"  { return(stem(3,"e","en")); }      
<verb,any>"stringing"  { return(stem(4,"g","ing")); }    
<verb,any>"striven"  { return(stem(3,"ve","en")); }      
<verb,any>"strode"  { return(stem(3,"ide","ed")); }      
<verb,any>"strove"  { return(stem(3,"ive","ed")); }      
<verb,any>"strown"  { return(stem(3,"ow","en")); }       
<verb,any>"struck"  { return(stem(3,"ike","ed")); }       /* en */
<verb,any>"strung"  { return(stem(3,"ing","ed")); }       /* en */
<verb,any>"stuck"  { return(stem(3,"ick","ed")); }        /* en */
<verb,any>"stung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"stunk"  { return(stem(3,"ink","en")); }       
<verb,any>"sung"  { return(stem(3,"ing","en")); }        
<verb,any>"sunk"  { return(stem(3,"ink","en")); }        
<verb,any>"sunken"  { return(stem(5,"ink","en")); }       /* disprefer */
<verb,any>"swam"  { return(stem(3,"wim","ed")); }        
<verb,any>"swept"  { return(stem(3,"eep","ed")); }        /* en */
<verb,any>"swinging"  { return(stem(4,"g","ing")); }     
<verb,any>"swollen"  { return(stem(5,"ell","en")); }     
<verb,any>"swore"  { return(stem(3,"ear","ed")); }       
<verb,any>"sworn"  { return(stem(3,"ear","en")); }       
<verb,any>"swum"  { return(stem(3,"wim","en")); }        
<verb,any>"swung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"taken"  { return(stem(3,"ke","en")); }        
<verb,any>"taught"  { return(stem(5,"each","ed")); }      /* en */
<verb,any>"taxying"  { return(stem(4,"i","ing")); }       /* disprefer */
<verb,any>"teed"  { return(stem(3,"ee","ed")); }          /* en */
<verb,any>"thought"  { return(stem(5,"ink","ed")); }      /* en */
<verb,any>"threw"  { return(stem(3,"row","ed")); }       
<verb,any>"thriven"  { return(stem(3,"ve","en")); }       /* disprefer */      
<verb,any>"throve"  { return(stem(3,"ive","ed")); }       /* disprefer */      
<verb,any>"thrown"  { return(stem(3,"ow","en")); }       
<verb,any>"tinged"  { return(stem(3,"ge","ed")); }        /* en */
<verb,any>"tingeing"  { return(stem(4,"e","ing")); }     
<verb,any>"tinging"  { return(stem(4,"ge","ing")); }      /* disprefer */
<verb,any>"told"  { return(stem(3,"ell","ed")); }         /* en */
<verb,any>"took"  { return(stem(3,"ake","ed")); }        
<verb,any>"tore"  { return(stem(3,"ear","ed")); }        
<verb,any>"torn"  { return(stem(3,"ear","en")); }        
<verb,any>"tramels"  { return(stem(3,"mel","s")); }       /* disprefer */
<verb,any>"transfixt"  { return(stem(3,"ix","ed")); }     /* en */ /* disprefer */
<verb,any>"tranship"  { return(stem(3,"ship","ed")); }    /* en */
<verb,any>"trod"  { return(stem(3,"read","ed")); }       
<verb,any>"trodden"  { return(stem(5,"ead","en")); }     
<verb,any>"typewriting"  { return(stem(4,"te","ing")); } 
<verb,any>"typewritten"  { return(stem(3,"e","en")); }   
<verb,any>"typewrote"  { return(stem(3,"ite","ed")); }   
<verb,any>"unbent"  { return(stem(3,"end","ed")); }       /* en */
<verb,any>"unbound"  { return(stem(4,"ind","ed")); }      /* en */
<verb,any>"unclad"  { return(stem(3,"lothe","ed")); }     /* en */
<verb,any>"underbought"  { return(stem(5,"uy","ed")); }   /* en */
<verb,any>"underfed"  { return(stem(3,"feed","ed")); }    /* en */
<verb,any>"undergirt"  { return(stem(3,"ird","ed")); }    /* en */
<verb,any>"undergone"  { return(stem(3,"o","en")); }     
<verb,any>"underlaid"  { return(stem(3,"ay","ed")); }     /* en */
<verb,any>"underlain"  { return(stem(3,"ie","en")); }    
<verb,any>"underlies"  { return(stem(2,"e","s")); }      
<verb,any>"underlying"  { return(stem(4,"ie","ing")); }  
<verb,any>"underpaid"  { return(stem(3,"ay","ed")); }     /* en */
<verb,any>"underselling"  { return(stem(4,"l","ing")); } 
<verb,any>"undershot"  { return(stem(3,"hoot","ed")); }   /* en */
<verb,any>"undersold"  { return(stem(3,"ell","ed")); }    /* en */
<verb,any>"understood"  { return(stem(3,"and","ed")); }   /* en */
<verb,any>"undertaken"  { return(stem(3,"ke","en")); }   
<verb,any>"undertook"  { return(stem(3,"ake","ed")); }   
<verb,any>"underwent"  { return(stem(4,"go","ed")); }    
<verb,any>"underwriting"  { return(stem(4,"te","ing")); }
<verb,any>"underwritten"  { return(stem(3,"e","en")); }  
<verb,any>"underwrote"  { return(stem(3,"ite","ed")); }  
<verb,any>"undid"  { return(stem(3,"do","ed")); }        
<verb,any>"undone"  { return(stem(3,"o","en")); }        
<verb,any>"unfroze"  { return(stem(3,"eeze","ed")); }    
<verb,any>"unfrozen"  { return(stem(4,"eeze","en")); }   
<verb,any>"unlaid"  { return(stem(3,"ay","ed")); }        /* en */
<verb,any>"unlearnt"  { return(stem(3,"rn","ed")); }      /* en */
<verb,any>"unmade"  { return(stem(3,"ake","ed")); }       /* en */
<verb,any>"unrove"  { return(stem(3,"eeve","ed")); }      /* en */
<verb,any>"unsaid"  { return(stem(3,"ay","ed")); }        /* en */
<verb,any>"unslinging"  { return(stem(4,"g","ing")); }   
<verb,any>"unslung"  { return(stem(3,"ing","ed")); }      /* en */
<verb,any>"unspoke"  { return(stem(3,"eak","ed")); }     
<verb,any>"unspoken"  { return(stem(4,"eak","en")); }    
<verb,any>"unstringing"  { return(stem(4,"g","ing")); }  
<verb,any>"unstrung"  { return(stem(3,"ing","ed")); }     /* en */
<verb,any>"unstuck"  { return(stem(3,"ick","ed")); }      /* en */
<verb,any>"unswore"  { return(stem(3,"ear","ed")); }     
<verb,any>"unsworn"  { return(stem(3,"ear","en")); }     
<verb,any>"untaught"  { return(stem(5,"each","ed")); }    /* en */
<verb,any>"unthought"  { return(stem(5,"ink","ed")); }    /* en */
<verb,any>"untrod"  { return(stem(3,"read","ed")); }     
<verb,any>"untrodden"  { return(stem(5,"ead","en")); }   
<verb,any>"unwound"  { return(stem(4,"ind","ed")); }      /* en */
<verb,any>"upbuilt"  { return(stem(3,"ild","ed")); }      /* en */
<verb,any>"upheld"  { return(stem(3,"old","ed")); }       /* en */
<verb,any>"uphove"  { return(stem(3,"eave","ed")); }      /* en */
<verb,any>"upped"  { return(stem(3,"","ed")); }           /* en */
<verb,any>"upping"  { return(stem(4,"","ing")); }        
<verb,any>"uprisen"  { return(stem(3,"se","en")); }      
<verb,any>"uprose"  { return(stem(3,"ise","ed")); }      
<verb,any>"upsprang"  { return(stem(3,"ing","ed")); }    
<verb,any>"upspringing"  { return(stem(4,"g","ing")); }  
<verb,any>"upsprung"  { return(stem(3,"ing","en")); }    
<verb,any>"upswept"  { return(stem(3,"eep","ed")); }      /* en */
<verb,any>"upswinging"  { return(stem(4,"g","ing")); }   
<verb,any>"upswollen"  { return(stem(5,"ell","en")); }    /* disprefer */
<verb,any>"upswung"  { return(stem(3,"ing","ed")); }      /* en */
<verb,any>"visaed"  { return(stem(3,"a","ed")); }         /* en */
<verb,any>"visaing"  { return(stem(4,"a","ing")); }      
<verb,any>"waylaid"  { return(stem(3,"ay","ed")); }      
<verb,any>"waylain"  { return(stem(3,"ay","en")); }      
<verb,any>"went"  { return(stem(4,"go","ed")); }         
<verb,any>"wept"  { return(stem(3,"eep","ed")); }         /* en */
<verb,any>"whipsawn"  { return(stem(3,"aw","en")); }     
<verb,any>"winterfed"  { return(stem(3,"feed","ed")); }   /* en */
<verb,any>"wiredrawn"  { return(stem(3,"aw","en")); }    
<verb,any>"wiredrew"  { return(stem(3,"raw","ed")); }    
<verb,any>"withdrawn"  { return(stem(3,"aw","en")); }    
<verb,any>"withdrew"  { return(stem(3,"raw","ed")); }    
<verb,any>"withheld"  { return(stem(3,"old","ed")); }     /* en */
<verb,any>"withstood"  { return(stem(3,"and","ed")); }    /* en */
<verb,any>"woke"  { return(stem(3,"ake","ed")); }        
<verb,any>"woken"  { return(stem(4,"ake","en")); }       
<verb,any>"won"  { return(stem(3,"win","ed")); }          /* en */
<verb,any>"wore"  { return(stem(3,"ear","ed")); }        
<verb,any>"worn"  { return(stem(3,"ear","en")); }        
<verb,any>"wound"  { return(stem(4,"ind","ed")); }        /* en */
<verb,any>"wove"  { return(stem(3,"eave","ed")); }       
<verb,any>"woven"  { return(stem(4,"eave","en")); }      
<verb,any>"wringing"  { return(stem(4,"g","ing")); }     
<verb,any>"writing"  { return(stem(4,"te","ing")); }     
<verb,any>"written"  { return(stem(3,"e","en")); }       
<verb,any>"wrote"  { return(stem(3,"ite","ed")); }       
<verb,any>"wrung"  { return(stem(3,"ing","ed")); }        /* en */
<verb,any>"ycleped"  { return(stem(7,"clepe","ed")); }    /* en */ /* disprefer */
<verb,any>"yclept"  { return(stem(6,"clepe","ed")); }     /* en */ /* disprefer */
<noun,any>"ABCs"  { return(stem(4,"ABC","s")); }         
<noun,any>"bacteria"  { return(stem(1,"um","s")); }      
<noun,any>"loggias"  { return(stem(1,"","s")); }                  
<noun,any>"bases"    { return(stem(2,"is","s")); }       
<noun,any>"schemata"  { return(stem(2,"","s")); }        
<noun,any>("curi"|"formul"|"vertebr"|"larv"|"uln"|"alumn")"ae"  { return(stem(1,"","s")); }
<noun,any>("beldam"|"boss"|"crux"|"larynx"|"sphinx"|"trellis"|"yes"|"atlas")"es"  { return(stem(2,"","s")); }
<noun,any>("alumn"|"loc"|"thromb"|"tars"|"streptococc"|"stimul"|"solid"|"radi"|"mag"|"cumul"|"bronch"|"bacill")"i"  { return(stem(1,"us","s")); }
<noun,any>("Brahman"|"German"|"dragoman"|"ottoman"|"shaman"|"talisman"|"Norman"|"Pullman"|"Roman")"s"  { return(stem(1,"","s")); }
<noun,any>("Czech"|"diptych"|"Sassenach"|"abdomen"|"alibi"|"aria"|"bandit"|"begonia"|"bikini"|"caryatid"|"colon"|"cornucopia"|"cromlech"|"cupola"|"dryad"|"eisteddfod"|"encyclopaedia"|"epoch"|"eunuch"|"flotilla"|"gardenia"|"gestalt"|"gondola"|"hierarch"|"hose"|"impediment"|"koala"|"loch"|"mania"|"manservant"|"martini"|"matriarch"|"monarch"|"oligarch"|"omen"|"parabola"|"pastorale"|"patriarch"|"pea"|"peninsula"|"pfennig"|"phantasmagoria"|"pibroch"|"poly"|"real"|"safari"|"sari"|"specimen"|"standby"|"stomach"|"swami"|"taxi"|"tech"|"toccata"|"triptych"|"villa"|"yogi"|"zloty")"s" { return(stem(1,"","s")); }
<noun,any>("asyl"|"sanct"|"rect"|"pl"|"pendul"|"mausole"|"hoodl"|"for")"ums"  { return(stem(1,"","s")); }
<noun,any>("Bantu"|"Bengalese"|"Beninese"|"Boche"|"Burmese"|"Chinese"|"Congolese"|"Gabonese"|"Guyanese"|"Japanese"|"Javanese"|"Lebanese"|"Maltese"|"Olympics"|"Portuguese"|"Senegalese"|"Siamese"|"Singhalese"|"Sinhalese"|"Sioux"|"Sudanese"|"Swiss"|"Taiwanese"|"Togolese"|"Vietnamese"|"aircraft"|"anopheles"|"apparatus"|"asparagus"|"barracks"|"bellows"|"bison"|"bluefish"|"bob"|"bourgeois"|"bream"|"brill"|"butterfingers"|"carp"|"catfish"|"chassis"|"chub"|"cod"|"codfish"|"coley"|"contretemps"|"corps"|"crawfish"|"crayfish"|"crossroads"|"cuttlefish"|"dace"|"dice"|"dogfish"|"doings"|"dory"|"downstairs"|"eldest"|"finnan"|"firstborn"|"fish"|"flatfish"|"flounder"|"fowl"|"fry"|"fries"|{A}+"-works"|"gasworks"|"glassworks"|"globefish"|"goldfish"|"grand"|"gudgeon"|"gulden"|"haddock"|"hake"|"halibut"|"headquarters"|"herring"|"hertz"|"horsepower"|"hovercraft"|"hundredweight"|"ironworks"|"jackanapes"|"kilohertz"|"kurus"|"kwacha"|"ling"|"lungfish"|"mackerel"|"means"|"megahertz"|"moorfowl"|"moorgame"|"mullet"|"offspring"|"pampas"|"parr"|"patois"|"pekinese"|"penn'orth"|"perch"|"pickerel"|"pike"|"pince-nez"|"plaice"|"precis"|"quid"|"rand"|"rendezvous"|"revers"|"roach"|"roux"|"salmon"|"samurai"|"series"|"shad"|"sheep"|"shellfish"|"smelt"|"spacecraft"|"species"|"starfish"|"stockfish"|"sunfish"|"superficies"|"sweepstakes"|"swordfish"|"tench"|"tope"|"triceps"|"trout"|"tuna"|"tunafish"|"tunny"|"turbot"|"undersigned"|"veg"|"waterfowl"|"waterworks"|"waxworks"|"whiting"|"wildfowl"|"woodworm"|"yen")  { return(xnull_stem()); }
<noun,any>"Aries" { return(stem(1,"s","s")); }           
<noun,any>"Pisces" { return(stem(1,"s","s")); }          
<noun,any>"Bengali" { return(stem(1,"i","s")); }         
<noun,any>"Somali" { return(stem(1,"i","s")); }          
<noun,any>"cicatrices" { return(stem(3,"x","s")); }      
<noun,any>"cachous" { return(stem(1,"","s")); }          
<noun,any>"confidantes" { return(stem(1,"","s")); }
<noun,any>"weltanschauungen" { return(stem(2,"","s")); } 
<noun,any>"apologetics" { return(stem(1,"","s")); }      
<noun,any>"dues" { return(stem(1,"","s")); }             
<noun,any>"whirrs" { return(stem(2,"","s")); }                    
<noun,any>"emus" { return(stem(1,"","s")); }
<noun,any>"equities" { return(stem(3,"y","s")); }        
<noun,any>"ethics" { return(stem(1,"","s")); }           
<noun,any>"extortions" { return(stem(1,"","s")); }       
<noun,any>"folks" { return(stem(1,"","s")); }            
<noun,any>"fumes" { return(stem(1,"","s")); }            
<noun,any>"fungi" { return(stem(1,"us","s")); }            
<noun,any>"ganglia" { return(stem(1,"on","s")); }        
<noun,any>"gnus" { return(stem(1,"","s")); }
<noun,any>"goings" { return(stem(1,"","s")); }           
<noun,any>"groceries" { return(stem(3,"y","s")); }       
<noun,any>"gurus" { return(stem(1,"","s")); }            
<noun,any>"halfpence" { return(stem(2,"ny","s")); }      
<noun,any>"hostilities" { return(stem(3,"y","s")); }     
<noun,any>"hysterics" { return(stem(1,"","s")); }        
<noun,any>"impromptus" { return(stem(1,"","s")); }       
<noun,any>"incidentals" { return(stem(1,"","s")); }      
<noun,any>"jujus" { return(stem(1,"","s")); }            
<noun,any>"landaus" { return(stem(1,"","s")); }          
<noun,any>"loins" { return(stem(1,"","s")); }            
<noun,any>"mains" { return(stem(1,"","s")); }            
<noun,any>"menus" { return(stem(1,"","s")); }            
<noun,any>"milieus" { return(stem(1,"","s")); }           /* disprefer */
<noun,any>"mockers" { return(stem(1,"","s")); }          
<noun,any>"morals" { return(stem(1,"","s")); }           
<noun,any>"motions" { return(stem(1,"","s")); }          
<noun,any>"mus" { return(stem(1,"","s")); }              
<noun,any>"nibs" { return(stem(1,"","s")); }             
<noun,any>"ninepins" { return(stem(1,"","s")); }         
<noun,any>"nippers" { return(stem(1,"","s")); }          
<noun,any>"oilskins" { return(stem(1,"","s")); }         
<noun,any>"overtones" { return(stem(1,"","s")); }        
<noun,any>"parvenus" { return(stem(1,"","s")); }         
<noun,any>"plastics" { return(stem(1,"","s")); }         
<noun,any>"polemics" { return(stem(1,"","s")); }         
<noun,any>"races" { return(stem(1,"","s")); }            
<noun,any>"refreshments" { return(stem(1,"","s")); }     
<noun,any>"reinforcements" { return(stem(1,"","s")); }   
<noun,any>"reparations" { return(stem(1,"","s")); }      
<noun,any>"returns" { return(stem(1,"","s")); }          
<noun,any>"rheumatics" { return(stem(1,"","s")); }       
<noun,any>"rudiments" { return(stem(1,"","s")); }        
<noun,any>"sadhus" { return(stem(1,"","s")); }           
<noun,any>"shires" { return(stem(1,"","s")); }           
<noun,any>"shivers" { return(stem(1,"","s")); }          
<noun,any>"sis" { return(stem(1,"","s")); }              
<noun,any>"spoils" { return(stem(1,"","s")); }           
<noun,any>"stamens" { return(stem(1,"","s")); }          
<noun,any>"stays" { return(stem(1,"","s")); }            
<noun,any>"subtitles" { return(stem(1,"","s")); }        
<noun,any>"tares" { return(stem(1,"","s")); }            
<noun,any>"thankyous" { return(stem(1,"","s")); }        
<noun,any>"thews" { return(stem(1,"","s")); }            
<noun,any>"toils" { return(stem(1,"","s")); }            
<noun,any>"tongs" { return(stem(1,"","s")); }            
<noun,any>"Hindus" { return(stem(1,"","s")); }           
<noun,any>"ancients" { return(stem(1,"","s")); }         
<noun,any>"bagpipes" { return(stem(1,"","s")); }         
<noun,any>"bleachers" { return(stem(1,"","s")); }        
<noun,any>"buttocks" { return(stem(1,"","s")); }         
<noun,any>"commons" { return(stem(1,"","s")); }          
<noun,any>"Israelis" { return(stem(1,"","s")); }         
<noun,any>"Israeli" { return(stem(1,"i","s")); }          /* disprefer */
<noun,any>"dodgems" { return(stem(1,"","s")); }          
<noun,any>"causeries" { return(stem(1,"","s")); }        
<noun,any>"quiches" { return(stem(1,"","s")); }          
<noun,any>"rations" { return(stem(1,"","s")); }          
<noun,any>"recompenses" { return(stem(1,"","s")); }      
<noun,any>"rinses" { return(stem(1,"","s")); }           
<noun,any>"lieder" { return(stem(2,"","s")); }           
<noun,any>"passers-by" { return(stem(4,"-by","s")); }    
<noun,any>"prolegomena" { return(stem(1,"on","s")); }    
<noun,any>"signore" { return(stem(1,"a","s")); }         
<noun,any>"nepalese" { return(stem(1,"e","s")); }        
<noun,any>"algae" { return(stem(1,"","s")); }            
<noun,any>"clutches" { return(stem(2,"","s")); }         
<noun,any>"continua" { return(stem(1,"um","s")); }       
<noun,any>"diggings" { return(stem(1,"","s")); }         
<noun,any>"K's" { return(stem(2,"","s")); }              
<noun,any>"seychellois" { return(stem(1,"s","s")); }     
<noun,any>"afterlives" { return(stem(3,"fe","s")); }     
<noun,any>"avens" { return(stem(1,"s","s")); }           
<noun,any>"axes" { return(stem(2,"is","s")); }           
<noun,any>"bonsai" { return(stem(1,"i","s")); }          
<noun,any>"coypus" { return(stem(1,"","s")); }
<noun,any>"duodena" { return(stem(1,"um","s")); }        
<noun,any>"genii" { return(stem(1,"e","s")); }           
<noun,any>"leaves" { return(stem(3,"f","s")); }          
<noun,any>"mantelshelves" { return(stem(3,"f","s")); }   
<noun,any>"meninges" { return(stem(3,"x","s")); }        
<noun,any>"moneybags" { return(stem(1,"s","s")); }       
<noun,any>"obbligati" { return(stem(1,"o","s")); }       
<noun,any>"orchises" { return(stem(2,"","s")); }         
<noun,any>"palais" { return(stem(1,"s","s")); }          
<noun,any>"pancreases" { return(stem(2,"","s")); }       
<noun,any>"phalanges" { return(stem(3,"x","s")); }       
<noun,any>"portcullises" { return(stem(2,"","s")); }     
<noun,any>"pubes" { return(stem(1,"s","s")); }           
<noun,any>"pulses" { return(stem(1,"","s")); }           
<noun,any>"ratlines" { return(stem(2,"","s")); }         
<noun,any>"signori" { return(stem(1,"","s")); }          
<noun,any>"spindle-shanks" { return(stem(1,"s","s")); }  
<noun,any>"substrata" { return(stem(1,"um","s")); }      
<noun,any>"woolies" { return(stem(3,"ly","s")); }        
<noun,any>"moggies" { return(stem(3,"y","s")); }         
<noun,any>("ghill"|"group"|"honk"|"mean"|"road"|"short"|"smooth"|"book"|"cabb"|"hank"|"toots"|"tough"|"trann")"ies" { return(stem(2,"e","s")); }
<noun,any>("christmas"|"judas")"es" { return(stem(2,"","s")); }
<noun,any>("flamb"|"plat"|"portmant"|"tabl"|"b"|"bur"|"trouss")"eaus" { return(stem(2,"u","s")); } /* disprefer */
<noun,any>("maharaj"|"raj"|"myn"|"mull")"ahs"  { return(stem(2,"","s")); }
<noun,any>("Boch"|"apocalyps"|"aps"|"ars"|"avalanch"|"backach"|"tens"|"relaps"|"barouch"|"brioch"|"cloch"|"collaps"|"cops"|"crech"|"crevass"|"douch"|"eclips"|"expans"|"expens"|"finess"|"glimps"|"gouach"|"heartach"|"impass"|"impuls"|"laps"|"mans"|"microfich"|"mouss"|"nonsens"|"pastich"|"peliss"|"poss"|"prolaps"|"psych")"es" { return(stem(1,"","s")); }
<noun,any>"addenda"  { return(stem(2,"dum","s")); }      
<noun,any>"adieux"  { return(stem(2,"u","s")); }         
<noun,any>"aides-de-camp"  { return(stem(9,"-de-camp","s")); }
<noun,any>"aliases"  { return(stem(2,"","s")); }         
<noun,any>"alkalies"  { return(stem(2,"","s")); }        
<noun,any>"alti"  { return(stem(2,"to","s")); }     
<noun,any>"amanuenses"  { return(stem(2,"is","s")); }    
<noun,any>"analyses"  { return(stem(2,"is","s")); }      
<noun,any>"anthraces"  { return(stem(3,"x","s")); }      
<noun,any>"antitheses"  { return(stem(2,"is","s")); }    
<noun,any>"aphides"  { return(stem(3,"s","s")); }        
<noun,any>"apices"  { return(stem(4,"ex","s")); }        
<noun,any>"appendices"  { return(stem(3,"x","s")); }     
<noun,any>"arboreta"  { return(stem(2,"tum","s")); }     
<noun,any>"atlantes"  { return(stem(4,"s","s")); }        /* disprefer */
<noun,any>"aurar"  { return(stem(5,"eyrir","s")); }     
<noun,any>"automata"  { return(stem(2,"ton","s")); }     
<noun,any>"axises"  { return(stem(2,"","s")); }           /* disprefer */
<noun,any>"bambini"  { return(stem(2,"no","s")); }       
<noun,any>"bandeaux"  { return(stem(2,"u","s")); }       
<noun,any>"banditti"  { return(stem(2,"","s")); }         /* disprefer */
<noun,any>"bassi"  { return(stem(2,"so","s")); }         
<noun,any>"beaux"  { return(stem(2,"u","s")); }          
<noun,any>"beeves"  { return(stem(3,"f","s")); }         
<noun,any>"bicepses"  { return(stem(2,"","s")); }        
<noun,any>"bijoux"  { return(stem(2,"u","s")); }         
<noun,any>"billets-doux"  { return(stem(6,"-doux","s")); }
<noun,any>"boraces"  { return(stem(3,"x","s")); }        
<noun,any>"bossies"  { return(stem(3,"","s")); }          /* disprefer */
<noun,any>"brainchildren"  { return(stem(3,"","s")); }   
<noun,any>"brothers-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"buckteeth"  { return(stem(4,"ooth","s")); }   
<noun,any>"bunde"  { return(stem(2,"d","s")); }          
<noun,any>"bureaux"  { return(stem(2,"u","s")); }        
<noun,any>"cacti"  { return(stem(1,"us","s")); }         
<noun,any>"calves"  { return(stem(3,"f","s")); }         
<noun,any>"calyces"  { return(stem(3,"x","s")); }        
<noun,any>"candelabra"  { return(stem(2,"rum","s")); }   
<noun,any>"capricci"  { return(stem(2,"cio","s")); }      /* disprefer */
<noun,any>"caribous"  { return(stem(2,"u","s")); }
<noun,any>"carides"  { return(stem(4,"yatid","s")); }     /* disprefer */
<noun,any>"catalyses"  { return(stem(2,"is","s")); }     
<noun,any>"cerebra"  { return(stem(2,"rum","s")); }      
<noun,any>"cervices"  { return(stem(3,"x","s")); }       
<noun,any>"chateaux"  { return(stem(2,"u","s")); }       
<noun,any>"children"  { return(stem(3,"","s")); }        
<noun,any>"chillies"  { return(stem(2,"","s")); }        
<noun,any>"chrysalides"  { return(stem(3,"s","s")); }    
<noun,any>"chrysalises"  { return(stem(2,"","s")); }      /* disprefer */
<noun,any>"ciceroni"  { return(stem(2,"ne","s")); }      
<noun,any>"cloverleaves"  { return(stem(3,"f","s")); }   
<noun,any>"coccyges"  { return(stem(3,"x","s")); }       
<noun,any>"codices"  { return(stem(4,"ex","s")); }       
<noun,any>"colloquies"  { return(stem(3,"y","s")); }     
<noun,any>"colones"  { return(stem(2,"","s")); }          /* disprefer */
<noun,any>"concertanti"  { return(stem(2,"te","s")); }   
<noun,any>"concerti"  { return(stem(2,"to","s")); }      
<noun,any>"concertini"  { return(stem(2,"no","s")); }    
<noun,any>"conquistadores"  { return(stem(2,"","s")); }  
<noun,any>"consortia"  { return(stem(1,"um","s")); }     
<noun,any>"contralti"  { return(stem(2,"to","s")); }     
<noun,any>"corpora"  { return(stem(3,"us","s")); }       
<noun,any>"corrigenda"  { return(stem(2,"dum","s")); }   
<noun,any>"cortices"  { return(stem(4,"ex","s")); }      
<noun,any>"crescendi"  { return(stem(2,"do","s")); }      /* disprefer */
<noun,any>"crises"  { return(stem(2,"is","s")); }        
<noun,any>"criteria"  { return(stem(2,"ion","s")); }     
<noun,any>"cruces"  { return(stem(3,"x","s")); }          /* disprefer */
<noun,any>"culs-de-sac"  { return(stem(8,"-de-sac","s")); }
<noun,any>"cyclopes"  { return(stem(2,"s","s")); }       
<noun,any>"cyclopses"  { return(stem(2,"","s")); }        /* disprefer */
<noun,any>"data"  { return(stem(2,"tum","s")); }         
<noun,any>"daughters-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"desiderata"  { return(stem(2,"tum","s")); }   
<noun,any>"diaereses"  { return(stem(2,"is","s")); }     
<noun,any>"diaerses"  { return(stem(3,"esis","s")); }     /* disprefer */
<noun,any>"dialyses"  { return(stem(2,"is","s")); }      
<noun,any>"diathses"  { return(stem(3,"esis","s")); }    
<noun,any>"dicta"  { return(stem(2,"tum","s")); }        
<noun,any>"diereses"  { return(stem(2,"is","s")); }      
<noun,any>"dilettantes"  { return(stem(2,"e","s")); }    
<noun,any>"dilettanti"  { return(stem(2,"te","s")); }     /* disprefer */
<noun,any>"divertimenti"  { return(stem(2,"to","s")); }  
<noun,any>"dogteeth"  { return(stem(4,"ooth","s")); }    
<noun,any>"dormice"  { return(stem(3,"ouse","s")); }     
<noun,any>"dryades"  { return(stem(2,"","s")); }          /* disprefer */
<noun,any>"dui"  { return(stem(2,"uo","s")); }            /* disprefer */
<noun,any>"duona"  { return(stem(2,"denum","s")); }       /* disprefer */
<noun,any>"duonas"  { return(stem(3,"denum","s")); }      /* disprefer */
<noun,any>"tutus"  { return(stem(1,"","s")); }                    
<noun,any>"vicissitudes"  { return(stem(1,"","s")); }             
<noun,any>"virginals"  { return(stem(1,"","s")); }                
<noun,any>"volumes"  { return(stem(1,"","s")); }                  
<noun,any>"zebus"  { return(stem(1,"","s")); }                    
<noun,any>"dwarves"  { return(stem(3,"f","s")); }        
<noun,any>"eisteddfodau"  { return(stem(2,"","s")); }     /* disprefer */
<noun,any>"ellipses"  { return(stem(2,"is","s")); }      
<noun,any>"elves"  { return(stem(3,"f","s")); }          
<noun,any>"emphases"  { return(stem(2,"is","s")); }      
<noun,any>"epicentres"  { return(stem(2,"e","s")); }     
<noun,any>"epiglottides"  { return(stem(3,"s","s")); }   
<noun,any>"epiglottises"  { return(stem(2,"","s")); }     /* disprefer */
<noun,any>"errata"  { return(stem(2,"tum","s")); }       
<noun,any>"exegeses"  { return(stem(2,"is","s")); }      
<noun,any>"eyeteeth"  { return(stem(4,"ooth","s")); }    
<noun,any>"fathers-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"feet"  { return(stem(3,"oot","s")); }         
<noun,any>"fellaheen"  { return(stem(3,"","s")); }       
<noun,any>"fellahin"  { return(stem(2,"","s")); }         /* disprefer */
<noun,any>"femora"  { return(stem(3,"ur","s")); }        
<noun,any>"flagstaves"  { return(stem(3,"ff","s")); }     /* disprefer */
<noun,any>"flambeaux"  { return(stem(2,"u","s")); }      
<noun,any>"flatfeet"  { return(stem(3,"oot","s")); }     
<noun,any>"fleurs-de-lis"  { return(stem(8,"-de-lis","s")); }
<noun,any>"fleurs-de-lys"  { return(stem(8,"-de-lys","s")); }
<noun,any>"flyleaves"  { return(stem(3,"f","s")); }      
<noun,any>"fora"  { return(stem(2,"rum","s")); }          /* disprefer */
<noun,any>"forcipes"  { return(stem(4,"eps","s")); }     
<noun,any>"forefeet"  { return(stem(3,"oot","s")); }     
<noun,any>"fulcra"  { return(stem(2,"rum","s")); }       
<noun,any>"gallowses"  { return(stem(2,"","s")); }       
<noun,any>"gases"  { return(stem(2,"","s")); }           
<noun,any>"gasses"  { return(stem(3,"","s")); }           /* disprefer */
<noun,any>"gateaux"  { return(stem(2,"u","s")); }        
<noun,any>"geese"  { return(stem(4,"oose","s")); }       
<noun,any>"gemboks"  { return(stem(4,"sbok","s")); }     
<noun,any>"genera"  { return(stem(3,"us","s")); }        
<noun,any>"geneses"  { return(stem(2,"is","s")); }       
<noun,any>"gentlemen-at-arms"  { return(stem(10,"an-at-arms","s")); }
<noun,any>"gestalten"  { return(stem(2,"","s")); }        /* disprefer */
<noun,any>"glissandi"  { return(stem(2,"do","s")); }     
<noun,any>"glottides"  { return(stem(3,"s","s")); }       /* disprefer */
<noun,any>"glottises"  { return(stem(2,"","s")); }       
<noun,any>"godchildren"  { return(stem(3,"","s")); }     
<noun,any>"goings-over"  { return(stem(6,"-over","s")); }
<noun,any>"grandchildren"  { return(stem(3,"","s")); }   
<noun,any>"halves"  { return(stem(3,"f","s")); }         
<noun,any>"hangers-on"  { return(stem(4,"-on","s")); }   
<noun,any>"helices"  { return(stem(3,"x","s")); }        
<noun,any>"hooves"  { return(stem(3,"f","s")); }         
<noun,any>"hosen"  { return(stem(2,"e","s")); }           /* disprefer */
<noun,any>"hypotheses"  { return(stem(2,"is","s")); }    
<noun,any>"iambi"  { return(stem(2,"b","s")); }          
<noun,any>"ibices"  { return(stem(4,"ex","s")); }         /* disprefer */
<noun,any>"ibises"  { return(stem(2,"","s")); }           /* disprefer */
<noun,any>"impedimenta"  { return(stem(2,"t","s")); }     /* disprefer */
<noun,any>"indices"  { return(stem(4,"ex","s")); }       
<noun,any>"intagli"  { return(stem(2,"lio","s")); }       /* disprefer */
<noun,any>"intermezzi"  { return(stem(2,"zo","s")); }    
<noun,any>"interregna"  { return(stem(2,"num","s")); }   
<noun,any>"irides"  { return(stem(3,"s","s")); }          /* disprefer */
<noun,any>"irises"  { return(stem(2,"","s")); }          
<noun,any>"is"  { return(stem(2,"is","s")); }            
<noun,any>"jacks-in-the-box"  { return(stem(12,"-in-the-box","s")); }
<noun,any>"kibbutzim"  { return(stem(2,"","s")); }       
<noun,any>"knives"  { return(stem(3,"fe","s")); }        
<noun,any>"kohlrabies"  { return(stem(2,"","s")); }      
<noun,any>"kronen"  { return(stem(2,"e","s")); }          /* disprefer */
<noun,any>"kroner"  { return(stem(2,"e","s")); }
<noun,any>"kronor"  { return(stem(2,"a","s")); }
<noun,any>"kronur"  { return(stem(2,"a","s")); }          /* disprefer */
<noun,any>"kylikes"  { return(stem(3,"x","s")); }        
<noun,any>"ladies-in-waiting"  { return(stem(14,"y-in-waiting","s")); }
<noun,any>"larynges"  { return(stem(3,"x","s")); }        /* disprefer */
<noun,any>"latices"  { return(stem(4,"ex","s")); }       
<noun,any>"leges"  { return(stem(3,"x","s")); }          
<noun,any>"libretti"  { return(stem(2,"to","s")); }      
<noun,any>"lice"  { return(stem(3,"ouse","s")); }        
<noun,any>"lire"  { return(stem(2,"ra","s")); }          
<noun,any>"lives"  { return(stem(3,"fe","s")); }         
<noun,any>"loaves"  { return(stem(3,"f","s")); }         
<noun,any>"loggie"  { return(stem(2,"ia","s")); }         /* disprefer */
<noun,any>"lustra"  { return(stem(2,"re","s")); }        
<noun,any>"lyings-in"  { return(stem(4,"-in","s")); }    
<noun,any>"macaronies"  { return(stem(2,"","s")); }      
<noun,any>"maestri"  { return(stem(2,"ro","s")); }       
<noun,any>"mantes"  { return(stem(2,"is","s")); }        
<noun,any>"mantises"  { return(stem(2,"","s")); }         /* disprefer */
<noun,any>"markkaa"  { return(stem(2,"a","s")); }        
<noun,any>"marquises"  { return(stem(2,"","s")); }       
<noun,any>"masters-at-arms"  { return(stem(9,"-at-arms","s")); }
<noun,any>"matrices"  { return(stem(3,"x","s")); }       
<noun,any>"matzoth"  { return(stem(2,"","s")); }         
<noun,any>"mausolea"  { return(stem(2,"eum","s")); }      /* disprefer */
<noun,any>"maxima"  { return(stem(2,"mum","s")); }       
<noun,any>"memoranda"  { return(stem(2,"dum","s")); }    
<noun,any>"men-at-arms"  { return(stem(10,"an-at-arms","s")); }
<noun,any>"men-o'-war"  { return(stem(9,"an-of-war","s")); } /* disprefer */
<noun,any>"men-of-war"  { return(stem(9,"an-of-war","s")); }
<noun,any>"menservants"  { return(stem(10,"anservant","s")); } /* disprefer */
<noun,any>"mesdemoiselles"  { return(stem(13,"ademoiselle","s")); }
<noun,any>"messieurs"  { return(stem(8,"onsieur","s")); }
<noun,any>"metatheses"  { return(stem(2,"is","s")); }    
<noun,any>"metropolises"  { return(stem(2,"","s")); }    
<noun,any>"mice"  { return(stem(3,"ouse","s")); }        
<noun,any>"milieux"  { return(stem(2,"u","s")); }        
<noun,any>"minima"  { return(stem(2,"mum","s")); }       
<noun,any>"momenta"  { return(stem(2,"tum","s")); }      
<noun,any>"monies"  { return(stem(3,"ey","s")); }        
<noun,any>"monsignori"  { return(stem(2,"r","s")); }     
<noun,any>"mooncalves"  { return(stem(3,"f","s")); }     
<noun,any>"mothers-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"naiades"  { return(stem(2,"","s")); }         
<noun,any>"necropoleis"  { return(stem(3,"is","s")); }    /* disprefer */
<noun,any>"necropolises"  { return(stem(2,"","s")); }    
<noun,any>"nemeses"  { return(stem(2,"is","s")); }       
<noun,any>"novelle"  { return(stem(2,"la","s")); }       
<noun,any>"oases"  { return(stem(2,"is","s")); }         
<noun,any>"obloquies"  { return(stem(3,"y","s")); }      
<noun,any>{A}+"hedra"  { return(stem(2,"ron","s")); }    
<noun,any>"optima"  { return(stem(2,"mum","s")); }       
<noun,any>"ora"  { return(stem(2,"s","s")); }            
<noun,any>"osar"  { return(stem(2,"","s")); }             /* disprefer */
<noun,any>"ossa"  { return(stem(2,"","s")); }             /* disprefer */
<noun,any>"ova"  { return(stem(2,"vum","s")); }          
<noun,any>"oxen"  { return(stem(2,"","s")); }            
<noun,any>"paralyses"  { return(stem(2,"is","s")); }     
<noun,any>"parentheses"  { return(stem(2,"is","s")); }   
<noun,any>"paris-mutuels"  { return(stem(9,"-mutuel","s")); }
<noun,any>"pastorali"  { return(stem(2,"le","s")); }      /* disprefer */
<noun,any>"patresfamilias"  { return(stem(11,"erfamilias","s")); }
<noun,any>"pease"  { return(stem(2,"","s")); }            /* disprefer */
<noun,any>"pekingese"  { return(stem(4,"ese","s")); }     /* disprefer */
<noun,any>"pelves"  { return(stem(2,"is","s")); }         /* disprefer */
<noun,any>"pelvises"  { return(stem(2,"","s")); }        
<noun,any>"pence"  { return(stem(2,"ny","s")); }         
<noun,any>"penes"  { return(stem(2,"is","s")); }          /* disprefer */
<noun,any>"penises"  { return(stem(2,"","s")); }         
<noun,any>"penknives"  { return(stem(3,"fe","s")); }     
<noun,any>"perihelia"  { return(stem(2,"ion","s")); }    
<noun,any>"pfennige"  { return(stem(2,"g","s")); }        /* disprefer */
<noun,any>"pharynges"  { return(stem(3,"x","s")); }      
<noun,any>"phenomena"  { return(stem(2,"non","s")); }    
<noun,any>"philodendra"  { return(stem(2,"ron","s")); }  
<noun,any>"pieds-a-terre"  { return(stem(9,"-a-terre","s")); }
<noun,any>"pineta"  { return(stem(2,"tum","s")); }       
<noun,any>"plateaux"  { return(stem(2,"u","s")); }       
<noun,any>"plena"  { return(stem(2,"num","s")); }        
<noun,any>"pocketknives"  { return(stem(3,"fe","s")); }  
<noun,any>"portmanteaux"  { return(stem(2,"u","s")); }   
<noun,any>"potlies"  { return(stem(4,"belly","s")); }    
<noun,any>"praxes"  { return(stem(2,"is","s")); }         /* disprefer */
<noun,any>"praxises"  { return(stem(2,"","s")); }        
<noun,any>"proboscides"  { return(stem(3,"s","s")); }     /* disprefer */
<noun,any>"proboscises"  { return(stem(2,"","s")); }     
<noun,any>"prostheses"  { return(stem(2,"is","s")); }    
<noun,any>"protozoa"  { return(stem(2,"oan","s")); }     
<noun,any>"pudenda"  { return(stem(2,"dum","s")); }      
<noun,any>"putti"  { return(stem(2,"to","s")); }         
<noun,any>"quanta"  { return(stem(2,"tum","s")); }       
<noun,any>"quarterstaves"  { return(stem(3,"ff","s")); } 
<noun,any>"reales"  { return(stem(2,"","s")); }           /* disprefer */
<noun,any>"recta"  { return(stem(2,"tum","s")); }         /* disprefer */
<noun,any>"referenda"  { return(stem(2,"dum","s")); }    
<noun,any>"reis"  { return(stem(2,"al","s")); }           /* disprefer */
<noun,any>"rondeaux"  { return(stem(2,"u","s")); }       
<noun,any>"rostra"  { return(stem(2,"rum","s")); }       
<noun,any>"runners-up"  { return(stem(4,"-up","s")); }   
<noun,any>"sancta"  { return(stem(2,"tum","s")); }        /* disprefer */
<noun,any>"sawboneses"  { return(stem(2,"","s")); }      
<noun,any>"scarves"  { return(stem(3,"f","s")); }        
<noun,any>"scherzi"  { return(stem(2,"zo","s")); }        /* disprefer */
<noun,any>"scrota"  { return(stem(2,"tum","s")); }       
<noun,any>"secretaries-general"  { return(stem(11,"y-general","s")); }
<noun,any>"selves"  { return(stem(3,"f","s")); }         
<noun,any>"sera"  { return(stem(2,"rum","s")); }          /* disprefer */
<noun,any>"seraphim"  { return(stem(2,"","s")); }        
<noun,any>"sheaves"  { return(stem(3,"f","s")); }        
<noun,any>"shelves"  { return(stem(3,"f","s")); }        
<noun,any>"simulacra"  { return(stem(2,"rum","s")); }    
<noun,any>"sisters-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"soli"  { return(stem(2,"lo","s")); }           /* disprefer */
<noun,any>"soliloquies"  { return(stem(3,"y","s")); }    
<noun,any>"sons-in-law"  { return(stem(8,"-in-law","s")); }
<noun,any>"spectra"  { return(stem(2,"rum","s")); }      
<noun,any>"sphinges"  { return(stem(3,"x","s")); }        /* disprefer */
<noun,any>"splayfeet"  { return(stem(3,"oot","s")); }    
<noun,any>"sputa"  { return(stem(2,"tum","s")); }        
<noun,any>"stamina"  { return(stem(3,"en","s")); }        /* disprefer */
<noun,any>"stelae"  { return(stem(2,"e","s")); }         
<noun,any>"stepchildren"  { return(stem(3,"","s")); }    
<noun,any>"sterna"  { return(stem(2,"num","s")); }       
<noun,any>"strata"  { return(stem(2,"tum","s")); }       
<noun,any>"stretti"  { return(stem(2,"to","s")); }       
<noun,any>"summonses"  { return(stem(2,"","s")); }       
<noun,any>"swamies"  { return(stem(2,"","s")); }          /* disprefer */
<noun,any>"swathes"  { return(stem(2,"","s")); }         
<noun,any>"synopses"  { return(stem(2,"is","s")); }      
<noun,any>"syntheses"  { return(stem(2,"is","s")); }     
<noun,any>"tableaux"  { return(stem(2,"u","s")); }       
<noun,any>"taxies"  { return(stem(2,"","s")); }           /* disprefer */
<noun,any>"teeth"  { return(stem(4,"ooth","s")); }       
<noun,any>"tempi"  { return(stem(2,"po","s")); }         
<noun,any>"tenderfeet"  { return(stem(3,"oot","s")); }   
<noun,any>"testes"  { return(stem(2,"is","s")); }        
<noun,any>"theses"  { return(stem(2,"is","s")); }        
<noun,any>"thieves"  { return(stem(3,"f","s")); }        
<noun,any>"thoraces"  { return(stem(3,"x","s")); }       
<noun,any>"titmice"  { return(stem(3,"ouse","s")); }     
<noun,any>"tootses"  { return(stem(2,"","s")); }         
<noun,any>"torsi"  { return(stem(2,"so","s")); }          /* disprefer */
<noun,any>"tricepses"  { return(stem(2,"","s")); }        /* disprefer */
<noun,any>"triumviri"  { return(stem(2,"r","s")); }      
<noun,any>"trousseaux"  { return(stem(2,"u","s")); }      /* disprefer */
<noun,any>"turves"  { return(stem(3,"f","s")); }         
<noun,any>"tympana"  { return(stem(2,"num","s")); }      
<noun,any>"ultimata"  { return(stem(2,"tum","s")); }     
<noun,any>"vacua"  { return(stem(2,"uum","s")); }         /* disprefer */      
<noun,any>"vertices"  { return(stem(4,"ex","s")); }      
<noun,any>"vertigines"  { return(stem(4,"o","s")); }     
<noun,any>"virtuosi"  { return(stem(2,"so","s")); }      
<noun,any>"vortices"  { return(stem(4,"ex","s")); }      
<noun,any>"wagons-lits"  { return(stem(6,"-lit","s")); } 
<noun,any>"weirdies"  { return(stem(2,"e","s")); }       
<noun,any>"werewolves"  { return(stem(3,"f","s")); }     
<noun,any>"wharves"  { return(stem(3,"f","s")); }        
<noun,any>"whippers-in"  { return(stem(4,"-in","s")); }  
<noun,any>"wolves"  { return(stem(3,"f","s")); }         
<noun,any>"woodlice"  { return(stem(3,"ouse","s")); }    
<noun,any>"yogin"  { return(stem(2,"i","s")); }           /* disprefer */
<noun,any>"zombies"  { return(stem(2,"e","s")); }        
<verb,any>"cryed"  { return(stem(3,"y","ed")); }          /* en */ /* disprefer */
<verb,any>"forted"  { return(stem(3,"te","ed")); }        /* en */
<verb,any>"forteing"  { return(stem(4,"e","ing")); }     
<verb,any>"picknicks"  { return(stem(2,"","s")); }       
<verb,any>"resold"  { return(stem(3,"ell","ed")); }       /* en */
<verb,any>"retold"  { return(stem(3,"ell","ed")); }       /* en */
<verb,any>"retying"  { return(stem(4,"ie","ing")); }     
<verb,any>"singed"  { return(stem(3,"ge","ed")); }        /* en */
<verb,any>"singeing"  { return(stem(4,"e","ing")); }     
<verb,any>"trecked"  { return(stem(4,"k","ed")); }        /* en */
<verb,any>"trecking"  { return(stem(5,"k","ing")); }     
<noun,any>"canvases"  { return(stem(2,"","s")); }        
<noun,any>"carcases"  { return(stem(1,"","s")); }        
<noun,any>"lenses"  { return(stem(2,"","s")); }          
<verb,any>"buffetts"  { return(stem(2,"","s")); }        
<verb,any>"plummetts"  { return(stem(2,"","s")); }        /* disprefer */
<verb,any>"gunslung"  { return(stem(3,"ing","ed")); }     /* en */
<verb,any>"gunslinging"  { return(stem(4,"g","ing")); }  
<noun,any>"biases"  { return(stem(2,"","s")); }          
<noun,any>"biscotti"  { return(stem(2,"to","s")); }      
<noun,any>"bookshelves"  { return(stem(3,"f","s")); }    
<noun,any>"palazzi"  { return(stem(2,"zo","s")); }       
<noun,any>"daises"  { return(stem(2,"","s")); }          
<noun,any>"reguli"  { return(stem(2,"lo","s")); }        
<noun,any>"steppes"  { return(stem(2,"e","s")); }        
<noun,any>"obsequies"  { return(stem(3,"y","s")); }      
<verb,noun,any>"busses"  { return(stem(3,"","s")); }
<verb,any>"bussed"  { return(stem(3,"","ed")); }          /* en */
<verb,any>"bussing"  { return(stem(4,"","ing")); }       
<verb,noun,any>"hocus-pocusses"  { return(stem(3,"","s")); }
<verb,noun,any>"hocusses"  { return(stem(3,"","s")); }   
<noun,any>"corpses"  { return(stem(1,"","s")); }

<verb,any>"ach"{EDING}    { return(semi_reg_stem(0,"e")); }       
<verb,any>"accustom"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"blossom"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"boycott"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"catalog"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>{PRE}*"creat"{EDING} { return(semi_reg_stem(0,"e")); }  
<verb,any>"finess"{ESEDING} { return(semi_reg_stem(0,"e")); }     
<verb,any>"interfer"{EDING} { return(semi_reg_stem(0,"e")); }     
<verb,any>{PRE}*"rout"{EDING} { return(semi_reg_stem(0,"e")); }   
<verb,any>"tast"{ESEDING} { return(semi_reg_stem(0,"e")); }       
<verb,any>"wast"{ESEDING} { return(semi_reg_stem(0,"e")); }       
<verb,any>"acquitt"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"ante"{ESEDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"arc"{EDING} { return(semi_reg_stem(0,"")); }           
<verb,any>"arck"{EDING} { return(semi_reg_stem(1,"")); }           /* disprefer */
<verb,any>"banquet"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"barrel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"bedevil"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"beguil"{EDING} { return(semi_reg_stem(0,"e")); }       
<verb,any>"bejewel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"bevel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"bias"{ESEDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"biass"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"bivouack"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"buckram"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"bushel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"canal"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"cancel"{EDING} { return(semi_reg_stem(0,"")); }         /* disprefer */
<verb,any>"carol"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"cavil"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"cbel"{EDING} { return(semi_reg_stem(0,"")); }          
<verb,any>"cbell"{EDING} { return(semi_reg_stem(1,"")); }          /* disprefer */
<verb,any>"channel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"chisel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"clep"{EDING} { return(semi_reg_stem(0,"e")); }         
<verb,any>"cloth"{ESEDING} { return(semi_reg_stem(0,"e")); }      
<verb,any>"coiff"{ESEDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"concertina"{EDING} { return(semi_reg_stem(0,"")); }    
<verb,any>"conga"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"coquett"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"counsel"{EDING} { return(semi_reg_stem(0,"")); }        /* disprefer */
<verb,any>"croquet"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"cudgel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"cupel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"debuss"{ESEDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"degass"{ESEDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"devil"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"diall"{EDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"disembowel"{EDING} { return(semi_reg_stem(0,"")); }    
<verb,any>"dishevel"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"drivel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"duell"{EDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"embuss"{ESEDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"empanel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"enamel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"equal"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"equall"{EDING} { return(semi_reg_stem(1,"")); }         /* disprefer */
<verb,any>"equipp"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"flannel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"frivol"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"frolick"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"fuell"{EDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"funnel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"gambol"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"gass"{ESEDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"gell"{EDING} { return(semi_reg_stem(1,"")); }          
<verb,any>"glace"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"gravel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"grovel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"gypp"{EDING} { return(semi_reg_stem(1,"")); }          
<verb,any>"hansel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"hatchel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"hocus-pocuss"{EDING} { return(semi_reg_stem(1,"")); }  
<verb,any>"hocuss"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"housel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"hovel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"impanel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"initiall"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"jewel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"kennel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"kernel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"label"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"laurel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"level"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"libel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"marshal"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"marvel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"medal"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"metal"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"mimick"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"misspell"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"model"{EDING} { return(semi_reg_stem(0,"")); }          /* disprefer */
<verb,any>"nickel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"nonpluss"{ESEDING} { return(semi_reg_stem(1,"")); }    
<verb,any>"outgass"{ESEDING} { return(semi_reg_stem(1,"")); }     
<verb,any>"outgeneral"{EDING} { return(semi_reg_stem(0,"")); }    
<verb,any>"overspill"{EDING} { return(semi_reg_stem(0,"")); }     
<verb,any>"pall"{EDING} { return(semi_reg_stem(0,"")); }          
<verb,any>"panel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"panick"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"parallel"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"parcel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"pedal"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"pencil"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"physick"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"picnick"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"pistol"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"polka"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"pommel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"precancel"{EDING} { return(semi_reg_stem(0,"")); }      /* disprefer */
<verb,any>"prolog"{EDING} { return(semi_reg_stem(0,"ue")); }      
<verb,any>"pummel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"quarrel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"quipp"{EDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"quitt"{EDING} { return(semi_reg_stem(1,"")); }         
<verb,any>"ravel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"recce"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"refuell"{EDING} { return(semi_reg_stem(1,"")); }       
<verb,any>"revel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"rival"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"roquet"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"rowel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"samba"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"saute"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"shellack"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"shovel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"shrivel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"sick"{EDING} { return(semi_reg_stem(1,"")); }          
<verb,any>"signal"{EDING} { return(semi_reg_stem(0,"")); }         /* disprefer */
<verb,any>"ski"{EDING} { return(semi_reg_stem(0,"")); }           
<verb,any>"snafu"{ESEDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"snivel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"sol-fa"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"spancel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"spiral"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"squatt"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"squibb"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"squidd"{EDING} { return(semi_reg_stem(1,"")); }        
<verb,any>"stencil"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"subpoena"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"subtotal"{EDING} { return(semi_reg_stem(0,"")); }       /* disprefer */
<verb,any>"swivel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"symbol"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"symboll"{EDING} { return(semi_reg_stem(1,"")); }        /* disprefer */
<verb,any>"talc"{EDING} { return(semi_reg_stem(0,"")); }          
<verb,any>"talck"{EDING} { return(semi_reg_stem(1,"")); }          /* disprefer */
<verb,any>"tassel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"taxi"{ESEDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"tinsel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"total"{EDING} { return(semi_reg_stem(0,"")); }          /* disprefer */
<verb,any>"towel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>"traffick"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"tramel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"tramell"{EDING} { return(semi_reg_stem(1,"")); }        /* disprefer */
<verb,any>"travel"{EDING} { return(semi_reg_stem(0,"")); }         /* disprefer */
<verb,any>"trowel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"tunnel"{EDING} { return(semi_reg_stem(0,"")); }        
<verb,any>"uncloth"{ESEDING} { return(semi_reg_stem(0,"e")); }    
<verb,any>"unkennel"{EDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"unravel"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"upswell"{EDING} { return(semi_reg_stem(0,"")); }       
<verb,any>"victuall"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"vitrioll"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"viva"{EDING} { return(semi_reg_stem(0,"")); }          
<verb,any>"yodel"{EDING} { return(semi_reg_stem(0,"")); }         
<verb,any>("di"|"ti"|"li"|"unti"|"beli"|"hogti"|"stymi")"es"  { return(stem(2,"e","s")); } /* en */
<verb,any>("di"|"ti"|"li"|"unti"|"beli"|"hogti"|"stymi")"ed"  { return(stem(2,"e","ed")); } /* en */
<verb,any>("d"|"t"|"l"|"unt"|"bel"|"hogt"|"stym")"ying"  { return(stem(4,"ie","ing")); } /* en */
<verb,any>"bias" { return(cnull_stem()); }                         
<verb,any>"canvas" { return(cnull_stem()); }                       
<verb,any>"canvas"{ESEDING} { return(semi_reg_stem(0,"")); }      
<verb,any>"embed" { return(cnull_stem()); }                         /* disprefer */
<verb,any>"focuss"{ESEDING} { return(semi_reg_stem(1,"")); }      
<verb,any>"gas" { return(cnull_stem()); }
<verb,any>"picknick"{EDING} { return(semi_reg_stem(1,"")); }      
<verb,any>("adher"|"ador"|"attun"|"bast"|"bor"|"can"|"centr"|"cit"|"compet"|"cop"|"complet"|"concret"|"condon"|"contraven"|"conven"|"cran"|"delet"|"delineat"|"dop"|"drap"|"dron"|"escap"|"excit"|"fort"|"gap"|"gazett"|"grop"|"hon"|"hop"|"ignit"|"ignor"|"incit"|"interven"|"inton"|"invit"|"landscap"|"manoeuvr"|"nauseat"|"normalis"|"outmanoeuvr"|"overaw"|"permeat"|"persever"|"pip"|"por"|"postpon"|"prun"|"rap"|"recit"|"reshap"|"rop"|"shap"|"shor"|"snor"|"snip"|"ston"|"tap"|"wip"){ESEDING} { return(semi_reg_stem(0,"e")); }
<verb,any>("ape"|"augur"|"belong"|"berth"|"burr"|"conquer"|"egg"|"forestall"|"froth"|"install"|"lacquer"|"martyr"|"mouth"|"murmur"|"pivot"|"preceed"|"prolong"|"purr"|"quell"|"recall"|"refill"|"remill"|"resell"|"retell"|"smooth"|"throng"|"twang"|"unearth"){EDING} { return(semi_reg_stem(0,"")); }
<noun,any>(({A}*"metr")|({A}*"litr")|({A}+"ett")|"acr"|"Aussi"|"budgi"|"catastroph"|"centr"|"clich"|"commi"|"cooli"|"curi"|"demesn"|"employe"|"evacue"|"fibr"|"headach"|"hord"|"magpi"|"manoeuvr"|"moggi"|"moustach"|"movi"|"nighti"|"programm"|"queu"|"sabr"|"sorti"|"tast"|"theatr"|"timbr"|"titr"|"wiseacr")"es" { return(stem(1,"","s")); }
<noun,any>"burnurns" { return(stem(1,"","s")); }                  
<noun,any>"carriageways" { return(stem(1,"","s")); }              
<noun,any>"cills" { return(stem(1,"","s")); }                     
<noun,any>("umbrell"|"utopi")"as" { return(stem(1,"","s")); }     
<noun,any>(({A}+"itis")|"abdomen"|"acacia"|"achimenes"|"alibi"|"alkali"|"ammonia"|"amnesia"|"anaesthesia"|"anesthesia"|"aria"|"arris"|"asphyxia"|"aspidistra"|"aubrietia"|"axis"|"begonia"|"bias"|"bikini"|"cannula"|"canvas"|"chili"|"chinchilla"|"Christmas"|"cornucopia"|"cupola"|"cyclamen"|"diabetes"|"diphtheria"|"dysphagia"|"encyclopaedia"|"ennui"|"escallonia"|"ferris"|"flotilla"|"forsythia"|"ganglia"|"gas"|"gondola"|"grata"|"guerrilla"|"haemophilia"|"hysteria"|"inertia"|"insignia"|"iris"|"khaki"|"koala"|"lens"|"macaroni"|"manilla"|"mania"|"mantis"|"martini"|"matins"|"memorabilia"|"metropolis"|"moa"|"morphia"|"nostalgia"|"omen"|"pantometria"|"parabola"|"paraphernalia"|"pastis"|"patella"|"patens"|"pelvis"|"peninsula"|"phantasmagoria"|"pneumonia"|"polyuria"|"portcullis"|"pyrexia"|"regalia"|"safari"|"salami"|"sari"|"saturnalia"|"spaghetti"|"specimen"|"subtopia"|"suburbia"|"syphilis"|"taxi"|"toccata"|"trellis"|"tutti"|"umbrella"|"utopia"|"villa"|"zucchini") { return(cnull_stem()); }
<noun,any>("acumen"|"Afrikaans"|"aphis"|"brethren"|"caries"|"confetti"|"contretemps"|"dais"|"debris"|"extremis"|"gallows"|"hors"|"hovis"|"hustings"|"innards"|"isosceles"|"maquis"|"minutiae"|"molasses"|"mortis"|"patois"|"pectoris"|"plumbites"|"series"|"tares"|"tennis"|"turps") { return(xnull_stem()); }
<noun,any>("accoutrements"|"aerodynamics"|"aeronautics"|"aesthetics"|"algae"|"amends"|"annals"|"arrears"|"assizes"|"auspices"|"backwoods"|"bacteria"|"banns"|"battlements"|"bedclothes"|"belongings"|"billiards"|"binoculars"|"bitters"|"blandishments"|"bleachers"|"blinkers"|"blues"|"breeches"|"brussels"|"clothes"|"clutches"|"commons"|"confines"|"contents"|"credentials"|"crossbones"|"damages"|"dealings"|"dentures"|"depths"|"devotions"|"diggings"|"doings"|"downs"|"dues"|"dynamics"|"earnings"|"eatables"|"eaves"|"economics"|"electrodynamics"|"electronics"|"entrails"|"environs"|"equities"|"ethics"|"eugenics"|"filings"|"finances"|"folks"|"footlights"|"fumes"|"furnishings"|"genitals"|"glitterati"|"goggles"|"goods"|"grits"|"groceries"|"grounds"|"handcuffs"|"headquarters"|"histrionics"|"hostilities"|"humanities"|"hydraulics"|"hysterics"|"illuminations"|"italics"|"jeans"|"jitters"|"kinetics"|"knickers"|"latitudes"|"leggings"|"likes"|"linguistics"|"lodgings"|"loggerheads"|"mains"|"manners"|"mathematics"|"means"|"measles"|"media"|"memoirs"|"metaphysics"|"mockers"|"motions"|"multimedia"|"munitions"|"news"|"nutria"|"nylons"|"oats"|"odds"|"oils"|"oilskins"|"optics"|"orthodontics"|"outskirts"|"overalls"|"pants"|"pantaloons"|"papers"|"paras"|"paratroops"|"particulars"|"pediatrics"|"phonemics"|"phonetics"|"physics"|"pincers"|"plastics"|"politics"|"proceeds"|"proceedings"|"prospects"|"pyjamas"|"rations"|"ravages"|"refreshments"|"regards"|"reinforcements"|"remains"|"respects"|"returns"|"riches"|"rights"|"savings"|"scissors"|"seconds"|"semantics"|"shades"|"shallows"|"shambles"|"shorts"|"singles"|"slacks"|"specifics"|"spectacles"|"spoils"|"statics"|"statistics"|"summons"|"supplies"|"surroundings"|"suspenders"|"takings"|"teens"|"telecommunications"|"tenterhooks"|"thanks"|"theatricals"|"thermodynamics"|"tights"|"toils"|"trappings"|"travels"|"troops"|"tropics"|"trousers"|"tweeds"|"underpants"|"vapours"|"vicissitudes"|"vitals"|"wages"|"wanderings"|"wares"|"whereabouts"|"whites"|"winnings"|"withers"|"woollens"|"workings"|"writings"|"yes") { return(xnull_stem()); }
<noun,any>("boati"|"bonhomi"|"clippi"|"creepi"|"deari"|"droppi"|"gendarmeri"|"girli"|"goali"|"haddi"|"kooki"|"kyri"|"lambi"|"lassi"|"mari"|"menageri"|"petti"|"reveri"|"snotti"|"sweeti")"es" { return(stem(1,"","s")); }
<verb,any>("buffet"|"plummet")"t"{EDING} { return(semi_reg_stem(1,"")); }
<verb,any>"gunsling" { return(cnull_stem()); }
<verb,any>"hamstring" { return(cnull_stem()); }
<verb,any>"shred" { return(cnull_stem()); }
<verb,any>"unfocuss"{ESEDING} { return(semi_reg_stem(1,"")); }    
<verb,any>("accret"|"clon"|"deplet"|"dethron"|"dup"|"excret"|"expedit"|"extradit"|"fet"|"finetun"|"gor"|"hing"|"massacr"|"obsolet"|"reconven"|"recreat"|"recus"|"reignit"|"swip"|"videotap"|"zon"){ESEDING} { return(semi_reg_stem(0,"e")); }
<verb,any>("backpedal"|"bankroll"|"bequeath"|"blackball"|"bottom"|"clang"|"debut"|"doctor"|"eyeball"|"factor"|"imperil"|"landfill"|"margin"|"multihull"|"occur"|"overbill"|"pilot"|"prong"|"pyramid"|"reinstall"|"relabel"|"remodel"|"snowball"|"socall"|"squirrel"|"stonewall"|"wrong"){EDING} { return(semi_reg_stem(0,"")); } /* disprefer */
<noun,any>("beasti"|"browni"|"cach"|"cadr"|"calori"|"champagn"|"cologn"|"cooki"|"druggi"|"eateri"|"emigr"|"emigre"|"employe"|"freebi"|"genr"|"kiddi"|"massacr"|"mooni"|"neckti"|"nich"|"prairi"|"softi"|"toothpast"|"willi")"es" { return(stem(1,"","s")); }
<noun,any>(({A}*"phobia")|"accompli"|"aegis"|"alias"|"anorexia"|"anti"|"artemisia"|"ataxia"|"beatlemania"|"blini"|"cafeteria"|"capita"|"cola"|"coli"|"deli"|"dementia"|"downstairs"|"upstairs"|"dyslexia"|"jakes"|"dystopia"|"encyclopedia"|"estancia"|"euphoria"|"euthanasia"|"fracas"|"fuss"|"gala"|"gorilla"|"GI"|"habeas"|"haemophilia"|"hemophilia"|"hoopla"|"hula"|"impatiens"|"informatics"|"intelligentsia"|"jacuzzi"|"kiwi"|"mafia"|"magnolia"|"malaria"|"maquila"|"marginalia"|"megalomania"|"mercedes"|"militia"|"mufti"|"muni"|"olympics"|"pancreas"|"paranoia"|"pastoris"|"pastrami"|"pepperoni"|"pepsi"|"pi"|"piroghi"|"pizzeria"|"pneumocystis"|"potpourri"|"proboscis"|"rabies"|"reggae"|"regimen"|"rigatoni"|"salmonella"|"sarsaparilla"|"semen"|"ski"|"sonata"|"spatula"|"stats"|"subtilis"|"sushi"|"tachyarrhythmia"|"tachycardia"|"tequila"|"tetris"|"thrips"|"timpani"|"tsunami"|"vaccinia"|"vanilla") { return(cnull_stem()); }
<noun,any>("acrobatics"|"athletics"|"basics"|"betters"|"bifocals"|"bowels"|"briefs"|"checkers"|"cognoscenti"|"denims"|"doldrums"|"dramatics"|"dungarees"|"ergonomics"|"genetics"|"gravitas"|"gymnastics"|"hackles"|"haves"|"hubris"|"ides"|"incidentals"|"ironworks"|"jinks"|"leavings"|"leftovers"|"logistics"|"makings"|"microelectronics"|"miniseries"|"mips"|"mores"|"oodles"|"pajamas"|"pampas"|"panties"|"payola"|"pickings"|"plainclothes"|"pliers"|"ravings"|"reparations"|"rudiments"|"scads"|"splits"|"stays"|"subtitles"|"sunglasss"|"sweepstakes"|"tatters"|"toiletries"|"tongs"|"trivia"|"tweezers"|"vibes"|"waterworks"|"woolens") { return(xnull_stem()); }
<noun,any>("biggi"|"bourgeoisi"|"bri"|"camaraderi"|"chinoiseri"|"coteri"|"doggi"|"geni"|"hippi"|"junki"|"lingeri"|"moxi"|"preppi"|"rooki"|"yuppi")"es"  { return(stem(1,"","s")); }
<verb,any>("chor"|"sepulchr"|"silhouett"|"telescop"){ESEDING}  { return(semi_reg_stem(0,"e")); }
<verb,any>("subpena"|"suds"){EDING} { return(semi_reg_stem(0,"")); }
<noun,any>(({A}+"philia")|"fantasia"|"Feis"|"Gras"|"Mardi")  { return(cnull_stem()); }
<noun,any>("calisthenics"|"heroics"|"rheumatics"|"victuals"|"wiles")  { return(xnull_stem()); }
<noun,any>("aunti"|"anomi"|"coosi"|"quicki")"es" { return(stem(1,"","s")); }
<noun,any>("absentia"|"bourgeois"|"pecunia"|"Syntaxis"|"uncia")  { return(cnull_stem()); }
<noun,any>("apologetics"|"goings"|"outdoors")  { return(xnull_stem()); }
<noun,any>"collies"  { return(stem(1,"","s")); }                   
<verb,any>"imbed"  { return(cnull_stem()); }
<verb,any>"precis"  { return(cnull_stem()); }
<verb,any>"precis"{ESEDING} { return(semi_reg_stem(0,"")); }      
<noun,any>("assagai"|"borzoi"|"calla"|"camellia"|"campanula"|"cantata"|"caravanserai"|"cedilla"|"cognomen"|"copula"|"corolla"|"cyclopaedia"|"dahlia"|"dhoti"|"dolmen"|"effendi"|"fibula"|"fistula"|"freesia"|"fuchsia"|"guerilla"|"hadji"|"hernia"|"houri"|"hymen"|"hyperbola"|"hypochondria"|"inamorata"|"kepi"|"kukri"|"mantilla"|"monomania"|"nebula"|"ovata"|"pergola"|"petunia"|"pharmacopoeia"|"phi"|"poinsettia"|"primula"|"rabbi"|"scapula"|"sequoia"|"sundae"|"tarantella"|"tarantula"|"tibia"|"tombola"|"topi"|"tortilla"|"uvula"|"viola"|"wisteria"|"zinnia")  { return(cnull_stem()); }
<noun,any>("tibi"|"nebul"|"uvul")"ae"  { return(stem(1,"","s")); } /* disprefer */
<noun,any>("arras"|"clitoris"|"muggins")"es" { return(stem(2,"","s")); }
<noun,any>("alms"|"biceps"|"calends"|"elevenses"|"eurhythmics"|"faeces"|"forceps"|"jimjams"|"jodhpurs"|"menses"|"secateurs"|"shears"|"smithereens"|"spermaceti"|"suds"|"trews"|"triceps"|"underclothes"|"undies"|"vermicelli")  { return(xnull_stem()); }
<noun,any>("albumen"|"alopecia"|"ambergris"|"amblyopia"|"ambrosia"|"analgesia"|"aphasia"|"arras"|"asbestos"|"asia"|"assegai"|"astrophysics"|"aubrietia"|"aula"|"avoirdupois"|"beriberi"|"bitumen"|"broccoli"|"cadi"|"callisthenics"|"collywobbles"|"curia"|"cybernetics"|"cyclops"|"cyclopedia"|"dickens"|"dietetics"|"dipsomania"|"dyspepsia"|"epidermis"|"epiglottis"|"erysipelas"|"fascia"|"finis"|"fives"|"fleur-de-lis"|"geophysics"|"geriatrics"|"glottis"|"haggis"|"hara-kiri"|"herpes"|"hoop-la"|"ibis"|"insomnia"|"kleptomania"|"kohlrabi"|"kris"|"kumis"|"litchi"|"litotes"|"loggia"|"magnesia"|"man-at-arms"|"manila"|"marquis"|"master-at-arms"|"mattins"|"melancholia"|"minutia"|"muggins"|"mumps"|"mi"|"myopia"|"necropolis"|"neuralgia"|"nibs"|"numismatics"|"nymphomania"|"obstetrics"|"okapi"|"onomatopoeia"|"ophthalmia"|"paraplegia"|"patchouli"|"paterfamilias"|"penis"|"piccalilli"|"praxis"|"precis"|"prophylaxis"|"pyrites"|"raffia"|"revers"|"rickets"|"rounders"|"rubella"|"saki"|"salvia"|"sassafras"|"sawbones"|"scabies"|"schnapps"|"scintilla"|"scrofula"|"sepia"|"stamen"|"si"|"swami"|"testis"|"therapeutics"|"tiddlywinks"|"verdigris"|"wadi"|"wapiti"|"yogi")  { return(cnull_stem()); }
<noun,any>("aeri"|"birdi"|"bogi"|"caddi"|"cock-a-leeki"|"colli"|"corri"|"cowri"|"dixi"|"eyri"|"faeri"|"gaucheri"|"gilli"|"knobkerri"|"laddi"|"mashi"|"meali"|"menageri"|"organdi"|"patisseri"|"pinki"|"pixi"|"stymi"|"talki")"es" { return(stem(1,"","s")); }
<noun,any>"humans"                  { return(stem(1,"","s")); }   
<noun,any>"slums"                   { return(stem(1,"","s")); }
<verb,any>(({A}*"-us")|"abus"|"accus"|"amus"|"arous"|"bemus"|"carous"|"contus"|"disabus"|"disus"|"dous"|"enthus"|"excus"|"grous"|"misus"|"mus"|"overus"|"perus"|"reus"|"rous"|"sous"|"us"|({A}*[hlmp]"ous")|({A}*[af]"us")){ESEDING} { return(semi_reg_stem(0,"e")); }
<noun,any>(({A}*"-abus")|({A}*"-us")|"abus"|"burnous"|"cayus"|"chanteus"|"chartreus"|"chauffeus"|"crus"|"disus"|"excus"|"grous"|"hypotenus"|"masseus"|"misus"|"mus"|"Ous"|"overus"|"poseus"|"reclus"|"reus"|"rus"|"us"|({A}*[hlmp]"ous")|({A}*[af]"us"))"es" { return(stem(1,"","s")); }
<noun,any>("ablutions"|"adenoids"|"aerobatics"|"afters"|"astronautics"|"atmospherics"|"bagpipes"|"ballistics"|"bell-bottoms"|"belles-lettres"|"blinders"|"bloomers"|"butterfingers"|"buttocks"|"bygones"|"cahoots"|"castanets"|"clappers"|"dodgems"|"dregs"|"duckboards"|"edibles"|"eurythmics"|"externals"|"extortions"|"falsies"|"fisticuffs"|"fleshings"|"fleur-de-lys"|"fours"|"gentleman-at-arms"|"geopolitics"|"giblets"|"gleanings"|"handlebars"|"heartstrings"|"homiletics"|"housetops"|"hunkers"|"hydroponics"|"kalends"|"knickerbockers"|"lees"|"lei"|"lieder"|"literati"|"loins"|"meanderings"|"meths"|"muniments"|"necessaries"|"nines"|"ninepins"|"nippers"|"nuptials"|"orthopaedics"|"paediatrics"|"phonics"|"polemics"|"pontificals"|"prelims"|"pyrotechnics"|"ravioli"|"rompers"|"ructions"|"scampi"|"scrapings"|"serjeant-at-arms"|"shires"|"smalls"|"steelworks"|"sweepings"|"vespers"|"virginals"|"waxworks") { return(xnull_stem()); }
<noun,any>("cannabis"|"corgi"|"envoi"|"hi-fi"|"kwela"|"lexis"|"muesli"|"sheila"|"ti"|"yeti") { return(cnull_stem()); }

<noun,any>("mounti"|"brasseri"|"granni"|"koppi"|"rotisseri")"es" { return(stem(1,"","s")); }

<noun,any>"cantharis"    { return(stem(1,"de","s")); }
<noun,any>"chamois"      { return(stem(1,"x","s")); }
<noun,any>"submatrices"  { return(stem(3,"x","s")); }
<noun,any>"mafiosi"      { return(stem(1,"o","s")); }
<noun,any>"pleura"       { return(stem(1,"on","s")); } 
<noun,any>"vasa"         { return(stem(1,"","s")); } 
<noun,any>"antipasti"    { return(stem(1,"o","s")); }

  /* -o / -oe */

<verb,any>("bastinado"|"bunco"|"bunko"|"carbonado"|"contango"|"crescendo"|"ditto"|"echo"|"embargo"|"fresco"|"hallo"|"halo"|"lasso"|"niello"|"radio"|"solo"|"stiletto"|"stucco"|"tally-ho"|"tango"|"torpedo"|"veto"|"zero")"ed"  { return(stem(2,"","ed")); }    /* en */
<verb,any>"ko'd"  { return(stem(3,"o","ed")); }           /* en */
<verb,any>"ko'ing"  { return(stem(4,"","ing")); }        
<verb,any>"ko's"  { return(stem(2,"","s")); }            
<verb,any>"tally-ho'd"  { return(stem(3,"","ed")); }     /* en */ /* disprefer */
<noun,any>("co"|"do"|"ko"|"no")"'s"   { return(stem(2,"","s")); }

<noun,any>("aloe"|"archfoe"|"canoe"|"doe"|"felloe"|"floe"|"foe"|"hammertoe"|"hoe"|"icefloe"|"mistletoe"|"oboe"|"roe"|({A}*"shoe")|"sloe"|"throe"|"tiptoe"|"toe"|"voe"|"woe")"s"  { return(stem(1,"","s")); }
<verb,any>("canoe"|"hoe"|"outwoe"|"rehoe"|({A}*"shoe")|"tiptoe"|"toe")"s"  { return(stem(1,"","s")); }

<noun,any>("tornedos"|"throes")  { return(xnull_stem()); }

  /* redundant in analysis; but in generation e.g. buffalo+s -> buffaloes */

<noun,any>("antihero"|"buffalo"|"dingo"|"domino"|"echo"|"go"|"grotto"|"hero"|"innuendo"|"mango"|"mato"|"mosquito"|"mulatto"|"potato"|"peccadillo"|"pentomino"|"superhero"|"tomato"|"tornado"|"torpedo"|"veto"|"volcano")"es" { return(stem(2,"","s")); }
<verb,any>("echo"|"forego"|"forgo"|"go"|"outdo"|"overdo"|"redo"|"torpedo"|"undergo"|"undo"|"veto")"es"  { return(stem(2,"","s")); }            

  /* -os / -oses */
  
<noun,any>("bathos"|"cross-purposes"|"kudos")  { return(xnull_stem()); }
<noun,any>"cos"                                { return(cnull_stem()); }

<noun,any>("chaos"|"cosmos"|"ethos"|"parados"|"pathos"|"rhinoceros"|"tripos"|"thermos"|"OS"|"reredos") { return(cnull_stem()); }
<noun,any>("chaos"|"cosmos"|"ethos"|"parados"|"pathos"|"rhinoceros"|"tripos"|"thermos"|"OS"|"reredos")"es"  { return(stem(2,"","s")); }

<noun,any>("anastomos"|"apotheos"|"arterioscleros"|"asbestos"|"cellulos"|"dermatos"|"diagnos"|"diverticulos"|"exostos"|"hemicellulos"|"histocytos"|"hypnos"|"meios"|"metamorphos"|"metempsychos"|"mitos"|"neuros"|"prognos"|"psychos"|"salmonellos"|"symbios"|"scleros"|"stenos"|"symbios"|"synchondros"|"treponematos"|"zoonos")"es"  { return(stem(2,"is","s")); }     

<noun,any>"pharoses"   { return(stem(4,"isee","s")); }  /* disprefer */

  /* -zes */

<noun,any>("adze"|"bronze")"s"        { return(stem(1,"","s")); } 
<noun,any>("fez"|"quiz")"zes"         { return(stem(3,"","s")); }
<noun,any>("fez"|"quiz")"es"          { return(stem(2,"","s")); }      /* disprefer */
<verb,any>("adz"|"bronz"){ESEDING}    { return(semi_reg_stem(0,"e")); }         
<verb,any>("quiz"|"whiz")"z"{ESEDING} { return(semi_reg_stem(1,"")); }
<verb,any>("quiz"|"whiz"){ESEDING}    { return(semi_reg_stem(0,"")); } /* disprefer */

<verb,noun,any>{A}+"uses"                { return(stem(2,"","s")); }
<verb,any>{A}+"used"                     { return(stem(2,"","ed")); } /* en */
<verb,any>{A}+"using"                    { return(stem(3,"","ing")); }

<noun,any>"pp." { return(stem(2,".","s")); }             
<noun,any>"m.p.s." { return(stem(6,"m.p.","s")); }       
<noun,any>("cons"|"miss"|"mrs"|"ms"|"n-s"|"pres"|"ss")"." { return(cnull_stem()); }
<noun,any>({A}|".")+".s."                { return(cnull_stem()); }
<noun,any>({A}|".")+".'s."               { return(stem(4,".","s")); } /* disprefer */
<noun,any>({A}|".")+"s."                 { return(stem(2,".","s")); }

<noun,any>{A}*"men"                 { return(stem(2,"an","s")); }
<noun,any>{A}*"wives"               { return(stem(3,"fe","s")); } 
<noun,any>{A}+"zoa"                 { return(stem(1,"on","s")); }
<noun,any>{A}+"iia"                 { return(stem(2,"um","s")); } /* disprefer */
<noun,any>{A}+"e"[mn]"ia"           { return(cnull_stem()); }
<noun,any>{A}+"ia"                  { return(stem(1,"um","s")); } /* disprefer */
<noun,any>{A}+"la"                  { return(stem(1,"um","s")); }
<noun,any>{A}+"i"                   { return(stem(1,"us","s")); } /* disprefer */
<noun,any>{A}+"ae"                  { return(stem(2,"a","s")); } /* disprefer */
<noun,any>{A}+"ata"                 { return(stem(3,"a","s")); } /* disprefer */

<verb,noun,any>("his"|"hers"|"theirs"|"ours"|"yours"|"as"|"its"|"this"|"during"|"something"|"nothing"|"anything"|"everything") { return(cnull_stem()); }
<verb,noun,any>{A}*("us"|"ss"|"sis"|"eed") { return(cnull_stem()); }
<verb,noun,any>{A}*{V}"ses"            { return(stem(1,"","s")); }
<verb,noun,any>{A}+{CXY}"zes"          { return(stem(2,"","s")); }
<verb,noun,any>{A}*{VY}"zes"           { return(stem(1,"","s")); }
<verb,noun,any>{A}+{S2}"es"            { return(stem(2,"","s")); }
<verb,noun,any>{A}+{V}"rses"           { return(stem(1,"","s")); }
<verb,noun,any>{A}+"onses"             { return(stem(1,"","s")); }
<verb,noun,any>{A}+{S}"es"             { return(stem(2,"","s")); }
<verb,noun,any>{A}+"thes"              { return(stem(1,"","s")); }
<verb,noun,any>{A}+{CXY}[cglsv]"es"    { return(stem(1,"","s")); }
<verb,noun,any>{A}+"ettes"             { return(stem(1,"","s")); }
<verb,noun,any>{A}+{C}"ies"            { return(stem(3,"y","s")); }
<verb,noun,any>{A}*{CXY}"oes"          { return(stem(2,"","s")); }  /* disprefer */
<verb,noun,any>{A}+"s"                 { return(stem(1,"","s")); }

<verb,any>{A}+{CXY}"zed"          { return(stem(2,"","ed")); }     /* en */
<verb,any>{A}*{VY}"zed"           { return(stem(1,"","ed")); }     /* en */
<verb,any>{A}+{S2}"ed"            { return(stem(2,"","ed")); }     /* en */
<verb,any>{A}+{CXY}"zing"         { return(stem(3,"","ing")); }
<verb,any>{A}*{VY}"zing"          { return(stem(3,"e","ing")); }
<verb,any>{A}+{S2}"ing"           { return(stem(3,"","ing")); } 
<verb,any>{C}+{V}"lled"           { return(stem(2,"","ed")); }     /* en */
<verb,any>{C}+{V}"lling"          { return(stem(3,"","ing")); } 
<verb,any>{A}*{C}{V}{CXY2}"ed"    { return(condub_stem(2,"","ed")); } /* en */
<verb,any>{A}*{C}{V}{CXY2}"ing"   { return(condub_stem(3,"","ing")); }

<verb,any>{CXY}+"ed"                { return(cnull_stem()); }
<verb,any>{PRE}*{C}{V}"nged"        { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+"icked"               { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}*{C}"ined"             { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}*{C}{V}[npwx]"ed"      { return(stem(2,"","ed")); }   /* en */ /* disprefer */
<verb,any>{PRE}*{C}+"ored"          { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+"ctored"              { return(stem(2,"","ed")); }   /* en */ /* disprefer */
<verb,any>{A}*{C}[clnt]"ored"       { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+[eo]"red"             { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+{C}"ied"              { return(stem(3,"y","ed")); }  /* en */
<verb,any>{A}*"qu"{V}{C}"ed"        { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+"u"{V}"ded"           { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}*{C}"leted"            { return(stem(2,"e","ed")); }  /* en */
<verb,any>{PRE}*{C}+[ei]"ted"       { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+[ei]"ted"             { return(stem(2,"","ed")); }   /* en */
<verb,any>{PRE}({CXY}{2})"eated"    { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}*{V}({CXY}{2})"eated"  { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+[eo]"ated"            { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+{V}"ated"             { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}*({V}{2})[cgsv]"ed"    { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}*({V}{2}){C}"ed"       { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+[rw]"led"             { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+"thed"                { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+"ued"                 { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+{CXY}[cglsv]"ed"      { return(stem(2,"e","ed")); }  /* en */
<verb,any>{A}+({CXY}{2})"ed"        { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+({VY}{2})"ed"         { return(stem(2,"","ed")); }   /* en */
<verb,any>{A}+"ed"                  { return(stem(2,"e","ed")); }  /* en */

<verb,any>{CXY}+"ing"                  { return(cnull_stem()); }
<verb,any>{PRE}*{C}{V}"nging"          { return(stem(3,"","ing")); } 
<verb,any>{A}+"icking"                 { return(stem(3,"","ing")); } 
<verb,any>{A}*{C}"ining"               { return(stem(3,"e","ing")); }
<verb,any>{A}*{C}{V}[npwx]"ing"        { return(stem(3,"","ing")); }  /* disprefer */
<verb,any>{A}*"qu"{V}{C}"ing"          { return(stem(3,"e","ing")); }
<verb,any>{A}+"u"{V}"ding"             { return(stem(3,"e","ing")); }
<verb,any>{A}*{C}"leting"              { return(stem(3,"e","ing")); }
<verb,any>{PRE}*{C}+[ei]"ting"         { return(stem(3,"e","ing")); }
<verb,any>{A}+[ei]"ting"               { return(stem(3,"","ing")); } 
<verb,any>{A}*{PRE}({CXY}{2})"eating"  { return(stem(3,"","ing")); }
<verb,any>{A}*{V}({CXY}{2})"eating"    { return(stem(3,"e","ing")); }
<verb,any>{A}+[eo]"ating"              { return(stem(3,"","ing")); } 
<verb,any>{A}+{V}"ating"               { return(stem(3,"e","ing")); }
<verb,any>{A}*({V}{2})[cgsv]"ing"      { return(stem(3,"e","ing")); }
<verb,any>{A}*({V}{2}){C}"ing"         { return(stem(3,"","ing")); } 
<verb,any>{A}+[rw]"ling"               { return(stem(3,"","ing")); } 
<verb,any>{A}+"thing"                  { return(stem(3,"e","ing")); }
<verb,any>{A}+{CXY}[cglsv]"ing"        { return(stem(3,"e","ing")); }
<verb,any>{A}+({CXY}{2})"ing"          { return(stem(3,"","ing")); } 
<verb,any>{A}+"uing"                   { return(stem(3,"e","ing")); }
<verb,any>{A}+({VY}{2})"ing"           { return(stem(3,"","ing")); } 
<verb,any>{A}+"ying"                   { return(stem(3,"","ing")); } 
<verb,any>{A}*{CXY}"oing"              { return(stem(3,"","ing")); } 
<verb,any>{PRE}*{C}+"oring"            { return(stem(3,"e","ing")); }
<verb,any>{A}+"ctoring"                { return(stem(3,"","ing")); }  /* disprefer */
<verb,any>{A}*{C}[clt]"oring"          { return(stem(3,"e","ing")); }
<verb,any>{A}+[eo]"ring"               { return(stem(3,"","ing")); } 
<verb,any>{A}+"ing"                    { return(stem(3,"e","ing")); }

<verb,noun,any>{G-}+"-"   { common_noun_stem(); return(yylex()); }
<verb,noun,any>{G-}+      { return(common_noun_stem()); }
<verb,noun,any>{SKIP}     { return(common_noun_stem()); }

<scan>"were"/_VBDR  { return(stem(4,"be","ed")); }
<scan>"was"/_VBDZ   { return(stem(3,"be","ed")); }
<scan>"am"/_VBM     { return(stem(2,"be","")); }      
<scan>"are"/_VBR    { return(stem(3,"be","")); }      
<scan>"is"/_VBZ     { return(stem(2,"be","s")); }     
<scan>"'d"/_VH      { return(stem(2,"have","ed")); }    /* disprefer */
<scan>"'d"/_VM      { return(stem(2,"would","")); }
<scan>"'s"/_VBZ     { return(stem(2,"be","s")); }       /* disprefer */
<scan>"'s"/_VDZ     { return(stem(2,"do","s")); }       /* disprefer */
<scan>"'s"/_VHZ     { return(stem(2,"have","s")); }     /* disprefer */
<scan>"'s"/_"$"     { return(stem(2,"'s","")); }             
<scan>"'s"/_POS     { return(stem(2,"'s","")); }             
<scan>"'s"/_CSA     { return(stem(2,"as","")); }             
<scan>"'s"/_CJS     { return(stem(2,"as","")); }             
<scan>"not"/_XX     { return(stem(3,"not","")); }            
<scan>"ai"/_VB      { return(stem(2,"be","")); }        /* disprefer */
<scan>"ai"/_VH      { return(stem(2,"have","")); }      /* disprefer */
<scan>"ca"/_VM      { return(stem(2,"can","")); }
<scan>"sha"/_VM     { return(stem(3,"shall","")); }          
<scan>"wo"/_VM      { return(stem(2,"will","")); }      /* disprefer */
<scan>"n't"/_XX     { return(stem(3,"not","")); }       /* disprefer */
<scan>"him"/_PPHO1  { return(stem(3,"he","")); }          
<scan>"her"/_PPHO1  { return(stem(3,"she","")); }         
<scan>"them"/_PPHO2 { return(stem(4,"they","")); }       
<scan>"me"/_PPIO1   { return(stem(2,"I","")); }            
<scan>"us"/_PPIO2   { return(stem(2,"we","")); }           
<scan>"I"/_PPIS1    { return(proper_name_stem()); }
<scan>"him"/_PNP    { return(stem(3,"he","")); }            
<scan>"her"/_PNP    { return(stem(3,"she","")); }           
<scan>"them"/_PNP   { return(stem(4,"they","")); }         
<scan>"me"/_PNP     { return(stem(2,"I","")); }              
<scan>"us"/_PNP     { return(stem(2,"we","")); }             
<scan>"I"/_PNP      { return(proper_name_stem()); }
<scan>{G}+/_N[^P] { BEGIN(noun); yyless(0); return(yylex()); }
<scan>{G}+/_NP    { return(proper_name_stem()); }
<scan>{G}+/_V     { BEGIN(verb); yyless(0); return(yylex()); }
<scan>{G}+/_      { return(common_noun_stem()); }
<scan>_{G}+       { if Option(tag_output) ECHO; return(1); }
<scan>{SKIP}      { return(common_noun_stem()); }

%%

char up8(char c)
{ if ('a' <= c && c <= 'z' || '\xE0' <= c && 
      c <= '\xFE' && c != '\xF7')
    return c-('a'-'A');
  else return c;
}

int scmp(const char *a, const char *b)
{ int i = 0, d = 0;
  while ((d=(int)up8(a[i])-(int)up8(b[i])) == 0 && 
	 a[i] != 0) i++;
  return d;
}

int vcmp(const void *a, const void *b)
{ return scmp(*((const char **)a), *((const char **)b));
}

int verbstem_n = 0;
char **verbstem_list = NULL;
 
int in_verbstem_list(char *a)
{ return verbstem_n > 0 &&
         bsearch(&a, verbstem_list, verbstem_n, sizeof(char*), 
		 &vcmp) != NULL;
}

void downcase( char *text, int len )
{int i;
 for ( i = 0; i<len; i++ )
    {if ( isupper(text[i]) )
      text[i] = 'a' + (text[i] - 'A');
    }
}

void capitalise( char *text, int len )
{int i;
 if ( islower(text[0]) ) text[0] = 'A' + (text[0] - 'a');
 for ( i = 1; i<len; i++ )
   {if ( isupper(text[i]) )
     text[i] = 'a' + (text[i] - 'A');
   }
}

int stem(int del, const char *add, const char *affix)
{int stem_length = yyleng - del;
 int i = 0;

 if Option(change_case) { downcase(yytext, stem_length); }
 for ( ;i < stem_length; ) putchar(yytext[i++]);
 if (!add[0] == '\0') printf("%s", add);

 if Option(print_affixes) { printf("+%s", affix); }

 return(1);
}

int condub_stem(int del, const char *add, const char *affix)
{int stem_length = yyleng - del;
 char d;
 
 if Option(change_case) { downcase(yytext, stem_length); }

 d = yytext[stem_length - 1];
 if (del > 0) { yytext[stem_length - 1] = '\0'; }
 
 if (in_verbstem_list(yytext))
   {printf("%s", yytext); } 
 else 
   {printf("%s%c", yytext, d); } 

 if Option(print_affixes) { printf("+%s", affix); }

 return(1);
}

int semi_reg_stem(int del, const char *add)
{int stem_length = 0;
 int i = 0;
 char *affix;
 
 if Option(change_case) { downcase(yytext, stem_length); }
 if (yytext[yyleng-1] == 's' || 
     yytext[yyleng-1] == 'S')
   {stem_length = yyleng - 2 - del; 
    affix = "s"; 
   }
 if (yytext[yyleng-1] == 'd' || 
     yytext[yyleng-1] == 'D')
   {stem_length = yyleng - 2 - del; 
    affix = "ed"; 
   }
 if (yytext[yyleng-1] == 'g' || 
     yytext[yyleng-1] == 'G')
   {stem_length = yyleng - 3 - del; 
    affix = "ing"; 
   }
 for ( ;i < stem_length; ) 
   {putchar(yytext[i++]);
   }
 printf("%s", add);
 if Option(print_affixes) 
   { printf("+%s", affix); 
   }
 
 return(1);
}

int proper_name_stem()
{
  if Option(change_case) { capitalise(yytext, yyleng); }
  ECHO;
  return(1);
}

int common_noun_stem()
{
  if Option(change_case) { downcase(yytext, yyleng); }
  ECHO;
  return(1);
}

  /* the +ed/+en form is the same as the stem */

int null_stem()
{
  return(common_noun_stem());
}

  /* word is a singular- or plural-only noun */

int xnull_stem()
{
  return(common_noun_stem());
}

  /* all inflected forms are the same as the stem */

int ynull_stem()
{
  return(common_noun_stem());
}

  /* this form is actually the stem so don't apply any generic analysis rules */

int cnull_stem()
{
  return(common_noun_stem());
}


char get_option(int argc, char *argv[], char *options, int *arg, 
		int *i)
{int   aa = *arg;
 int   ii = *i;
 char *opt, letter;

 if (aa > (argc - 1)) {
     *arg = aa;    
     *i = 0;
     return 0;}
  if (argv[aa][ii] == 0)
   {*arg =  aa + 1;
    ii  = 0;
    return 0;
   }
  if (aa > (argc - 1)) {
    *arg = aa;    
    *i = 0;
    return 0; 
  }
 do
   {if (aa == 1 && ii == 0 && argv[aa][ii] == '-') ii += 1; 
    letter = argv[aa][ii++];
	if ((opt = strchr(options, letter)) == NULL)
	  {fprintf(stderr, "Unknown option '%c' ignored\n", letter);
	  }
	else
	    { 
	      break;
	    }
    } while(forever); 
 *arg = aa; 
 *i   = ii; 
 return letter;
}

int read_verbstem(char *fn)
{ char w[64];
  int n = 0, i, j, fs;
  FILE *f = fopen(fn, "r");

  if (f == NULL) fprintf(stderr, "File with consonant doubling verb stems not found (\"%s\").\n", fn);
  else
  { while (1)
    { fs = fscanf(f, " %n%63s%n", &i, w, &j);
      if (fs == 0 || fs == EOF) break;
      if (verbstem_n == n)
        verbstem_list = (char **)realloc(verbstem_list, (n += 256) * sizeof(char*));
      verbstem_list[verbstem_n] = (char *)malloc(j-i+1);
      strcpy(verbstem_list[verbstem_n++], w);
    }
    fclose(f);
    qsort(verbstem_list, verbstem_n, sizeof(char*), &vcmp);
  }
}

BOOL read_verbstem_file(char *argv[], 
		    unsigned int maxbuff, int *arg, int *i)
{
 int ok = 1;

 if (strlen(argv[*arg]+(*i)) > maxbuff)
    {fprintf(stderr, "Argument to option f too long\n");
     ok = 0;
    }
   else read_verbstem(argv[*arg]);


 return ok;
}

void  set_up_options(int argc, char *argv[])
{char opt;
 int  arg = 1;
 int  i = 0;
 char *opt_string = "actuf:"; /* don't need : now */

 /* Initialize options */
 UnSetOption(print_affixes);
 SetOption(change_case);
 UnSetOption(tag_output);
 UnSetOption(fspec);

 state = scan;

 while ((opt = get_option(argc, argv, opt_string, &arg, &i)) != 0)
    {switch (opt)
	{case 'a': SetOption(print_affixes);
	           break;
	 case 'c': UnSetOption(change_case);
	           break;
	 case 't': SetOption(tag_output);
	           break;
	 case 'u': state = any;
	           break;
	 case 'f': SetOption(fspec);
	           break;
	}
    }

  if (Option(fspec)) { 
    if (arg > (argc - 1)) fprintf(stderr, "File with consonant doubling verb stems not specified\n");
    else { read_verbstem_file(argv, MAXSTR, &arg, &i);}
  }
  else read_verbstem("verbstem.list");
  }

int main(int argc, char **argv) 
{ set_up_options(argc, argv);

  BEGIN(state);
  while ( yylex() ) { BEGIN(state); } ;
  }

