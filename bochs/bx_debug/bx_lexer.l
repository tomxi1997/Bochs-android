%{
/////////////////////////////////////////////////////////////////////////
// $Id$
/////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <string.h>

#ifdef WIN32
	#include <io.h>
	#define YY_NO_UNISTD_H
#endif

#include "debug.h"
#if BX_DEBUGGER

#include "bx_parser.h"

int bx_yyinput(char *buf, int max_size);
#undef YY_INPUT
#define YY_INPUT(buf, ret, max_size) (ret = bx_yyinput(buf, max_size))

static char    *lex_input_ptr = NULL;
static unsigned lex_input_size = 0;

#if BX_SUPPORT_X86_64
  #define LONG_MODE_8BL_REG(reg) \
     { bxlval.uval = reg; return(BX_TOKEN_8BL_REG); }
  #define LONG_MODE_16B_REG(reg) \
     { bxlval.uval = reg; return(BX_TOKEN_16B_REG); }
  #define LONG_MODE_32B_REG(reg) \
     { bxlval.uval = reg; return(BX_TOKEN_32B_REG); }
  #define LONG_MODE_64B_REG(reg) \
     { bxlval.uval = reg; return(BX_TOKEN_64B_REG); }
#else
  #define LONG_MODE_8BL_REG(reg) \
     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
  #define LONG_MODE_16B_REG(reg) \
     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
  #define LONG_MODE_32B_REG(reg) \
     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
  #define LONG_MODE_64B_REG(reg) \
     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
#endif

#if BX_SUPPORT_EVEX
  #define EVEX_OPMASK_REG(reg) \
     { bxlval.uval = reg; return(BX_TOKEN_OPMASK_REG); }
#else
  #define EVEX_OPMASK_REG(reg) \
     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
#endif

%}

%x EXAMINE
%x DISASM

%%
<*>[ \t]+       ; // eat up whitespace
set             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SET); }
on              { bxlval.bval = 1; return(BX_TOKEN_ON); }
off             { bxlval.bval = 0; return(BX_TOKEN_OFF); }
crc             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_CRC); }
c               |
cont            |
continue        { bxlval.sval = strdup(bxtext); return(BX_TOKEN_CONTINUE); }
if              { bxlval.sval = strdup(bxtext); return(BX_TOKEN_IF); }
step            |
s               { bxlval.sval = strdup(bxtext); return(BX_TOKEN_STEPN); }
next            |
n               |
p               { bxlval.sval = strdup(bxtext); return(BX_TOKEN_STEP_OVER); }
blist           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LIST_BREAK); }
vb|vbreak       { bxlval.sval = strdup(bxtext); return(BX_TOKEN_VBREAKPOINT); }
lb|lbreak       { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LBREAKPOINT); }
break           |
b|pb            |
pbreak          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PBREAKPOINT); }
info            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_INFO); }
cr		|
creg		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_CONTROL_REGS); }
dr		|
dreg		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_DEBUG_REGS); }
sreg		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_SEGMENT_REGS); }
r               { bxlval.sval = strdup(bxtext); return(BX_TOKEN_R); }
reg|regs        |
registers       { bxlval.sval = strdup(bxtext); return(BX_TOKEN_REGS); }
fp|fpu          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_FPU); }
sse|xmm         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_XMM); }
ymm             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_YMM); }
zmm             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_ZMM); }
avx             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_AVX); }
amx             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_AMX); }
tile            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TILE); }
mmx             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_MMX); }
cpu             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_CPU); }
idt		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_IDT); }
ivt		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_IVT); }
gdt		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_GDT); }
ldt		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_LDT); }
tss		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_TSS); }
tab		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_TAB); }
linux           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LINUX); }
delete          |
del             |
d               { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DEL_BREAKPOINT); }
bpe             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_ENABLE_BREAKPOINT); }
bpd             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DISABLE_BREAKPOINT); }
quit            |
exit            |
q               { bxlval.sval = strdup(bxtext); return(BX_TOKEN_QUIT); }
x               |
xp              { BEGIN(EXAMINE); bxlval.sval = strdup(bxtext); return(BX_TOKEN_EXAMINE); }
restore         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_RESTORE); }
writemem        { bxlval.sval = strdup(bxtext); return(BX_TOKEN_WRITEMEM); }
loadmem         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LOADMEM); }
setpmem         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SETPMEM); }
deref           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DEREF); }
query           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_QUERY); }
pending         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PENDING); }
take            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TAKE); }
dma             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DMA); }
irq             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_IRQ); }
smi             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SMI); }
nmi             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_NMI); }
tlb             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TLB); }
u               |
disasm          { BEGIN(DISASM); bxlval.sval = strdup(bxtext); return(BX_TOKEN_DISASM); }
instrument      { bxlval.sval = strdup(bxtext); return(BX_TOKEN_INSTRUMENT); }
stop            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_STOP); }
doit            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DOIT); }
trace           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TRACE); }
trace-reg   	{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_TRACEREG); }
trace-mem   	{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_TRACEMEM); }
switch-mode	{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_SWITCH_MODE); }
size		{ bxlval.sval = strdup(bxtext); return(BX_TOKEN_SIZE); }
ptime           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PTIME); }
sb              { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TIMEBP); }
sba             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_TIMEBP_ABSOLUTE); }
modebp          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_MODEBP); }
vmexitbp        { bxlval.sval = strdup(bxtext); return(BX_TOKEN_VMEXITBP); }
print-stack     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PRINT_STACK); }
bt              { bxlval.sval = strdup(bxtext); return(BX_TOKEN_BT); }
watch           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_WATCH); }
unwatch         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_UNWATCH); }
read            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_READ); }
w|write         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_WRITE); }
show            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SHOW); }
ldsym           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LOAD_SYMBOLS); }
setmagicbps     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SET_MAGIC_BREAK_POINTS); }
clrmagicbps     { bxlval.sval = strdup(bxtext); return(BX_TOKEN_CLEAR_MAGIC_BREAK_POINTS); }
symbols         { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SYMBOLS); }
slist           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LIST_SYMBOLS); }
global          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GLOBAL); }
where           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_WHERE); }
print-string    { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PRINT_STRING); }
page            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_PAGE); }
device          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_DEVICE); }
a|all           { bxlval.sval = strdup(bxtext); return(BX_TOKEN_ALL); }
al              { bxlval.uval = BX_8BIT_REG_AL; return(BX_TOKEN_8BL_REG);}
bl              { bxlval.uval = BX_8BIT_REG_BL; return(BX_TOKEN_8BL_REG);}
cl              { bxlval.uval = BX_8BIT_REG_CL; return(BX_TOKEN_8BL_REG);}
dl              { bxlval.uval = BX_8BIT_REG_DL; return(BX_TOKEN_8BL_REG);}
sil             { LONG_MODE_8BL_REG(BX_8BIT_REG_SIL); }
dil             { LONG_MODE_8BL_REG(BX_8BIT_REG_DIL); }
spl             { LONG_MODE_8BL_REG(BX_8BIT_REG_SPL); }
bpl             { LONG_MODE_8BL_REG(BX_8BIT_REG_BPL); }
r8b             { LONG_MODE_8BL_REG(BX_8BIT_REG_R8);  }
r9b             { LONG_MODE_8BL_REG(BX_8BIT_REG_R9);  }
r10b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R10); }
r11b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R11); }
r12b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R12); }
r13b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R13); }
r14b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R14); }
r15b            { LONG_MODE_8BL_REG(BX_8BIT_REG_R15); }
ah              { bxlval.uval = BX_8BIT_REG_AH; return(BX_TOKEN_8BH_REG);}
bh              { bxlval.uval = BX_8BIT_REG_BH; return(BX_TOKEN_8BH_REG);}
ch              { bxlval.uval = BX_8BIT_REG_CH; return(BX_TOKEN_8BH_REG);}
dh              { bxlval.uval = BX_8BIT_REG_DH; return(BX_TOKEN_8BH_REG);}
ax              { bxlval.uval = BX_16BIT_REG_AX; return(BX_TOKEN_16B_REG);}
bx              { bxlval.uval = BX_16BIT_REG_BX; return(BX_TOKEN_16B_REG);}
cx              { bxlval.uval = BX_16BIT_REG_CX; return(BX_TOKEN_16B_REG);}
dx              { bxlval.uval = BX_16BIT_REG_DX; return(BX_TOKEN_16B_REG);}
si              { bxlval.uval = BX_16BIT_REG_SI; return(BX_TOKEN_16B_REG);}
di              { bxlval.uval = BX_16BIT_REG_DI; return(BX_TOKEN_16B_REG);}
bp              { bxlval.uval = BX_16BIT_REG_BP; return(BX_TOKEN_16B_REG);}
sp              { bxlval.uval = BX_16BIT_REG_SP; return(BX_TOKEN_16B_REG);}
r8w             { LONG_MODE_16B_REG(BX_16BIT_REG_R8);  }
r9w             { LONG_MODE_16B_REG(BX_16BIT_REG_R9);  }
r10w            { LONG_MODE_16B_REG(BX_16BIT_REG_R10); }
r11w            { LONG_MODE_16B_REG(BX_16BIT_REG_R11); }
r12w            { LONG_MODE_16B_REG(BX_16BIT_REG_R12); }
r13w            { LONG_MODE_16B_REG(BX_16BIT_REG_R13); }
r14w            { LONG_MODE_16B_REG(BX_16BIT_REG_R14); }
r15w            { LONG_MODE_16B_REG(BX_16BIT_REG_R15); }
eax             { bxlval.uval = BX_32BIT_REG_EAX; return(BX_TOKEN_32B_REG);}
ebx             { bxlval.uval = BX_32BIT_REG_EBX; return(BX_TOKEN_32B_REG);}
ecx             { bxlval.uval = BX_32BIT_REG_ECX; return(BX_TOKEN_32B_REG);}
edx             { bxlval.uval = BX_32BIT_REG_EDX; return(BX_TOKEN_32B_REG);}
esi             { bxlval.uval = BX_32BIT_REG_ESI; return(BX_TOKEN_32B_REG);}
edi             { bxlval.uval = BX_32BIT_REG_EDI; return(BX_TOKEN_32B_REG);}
ebp             { bxlval.uval = BX_32BIT_REG_EBP; return(BX_TOKEN_32B_REG);}
esp             { bxlval.uval = BX_32BIT_REG_ESP; return(BX_TOKEN_32B_REG);}
r8d             { LONG_MODE_32B_REG(BX_32BIT_REG_R8);  }
r9d             { LONG_MODE_32B_REG(BX_32BIT_REG_R9);  }
r10d            { LONG_MODE_32B_REG(BX_32BIT_REG_R10); }
r11d            { LONG_MODE_32B_REG(BX_32BIT_REG_R11); }
r12d            { LONG_MODE_32B_REG(BX_32BIT_REG_R12); }
r13d            { LONG_MODE_32B_REG(BX_32BIT_REG_R13); }
r14d            { LONG_MODE_32B_REG(BX_32BIT_REG_R14); }
r15d            { LONG_MODE_32B_REG(BX_32BIT_REG_R15); }
rax             { LONG_MODE_64B_REG(BX_64BIT_REG_RAX); }
rbx             { LONG_MODE_64B_REG(BX_64BIT_REG_RBX); }
rcx             { LONG_MODE_64B_REG(BX_64BIT_REG_RCX); }
rdx             { LONG_MODE_64B_REG(BX_64BIT_REG_RDX); }
rsi             { LONG_MODE_64B_REG(BX_64BIT_REG_RSI); }
rdi             { LONG_MODE_64B_REG(BX_64BIT_REG_RDI); }
rsp             { LONG_MODE_64B_REG(BX_64BIT_REG_RSP); }
rbp             { LONG_MODE_64B_REG(BX_64BIT_REG_RBP); }
r8              { LONG_MODE_64B_REG(BX_64BIT_REG_R8);  }
r9              { LONG_MODE_64B_REG(BX_64BIT_REG_R9);  }
r10             { LONG_MODE_64B_REG(BX_64BIT_REG_R10); }
r11             { LONG_MODE_64B_REG(BX_64BIT_REG_R11); }
r12             { LONG_MODE_64B_REG(BX_64BIT_REG_R12); }
r13             { LONG_MODE_64B_REG(BX_64BIT_REG_R13); }
r14             { LONG_MODE_64B_REG(BX_64BIT_REG_R14); }
r15             { LONG_MODE_64B_REG(BX_64BIT_REG_R15); }
ip              { return(BX_TOKEN_REG_IP); }
eip             { return(BX_TOKEN_REG_EIP);}
rip             { return(BX_TOKEN_REG_RIP);}
ssp             { return(BX_TOKEN_REG_SSP);}
cs              { bxlval.uval = BX_SEG_REG_CS; return(BX_TOKEN_CS); }
es              { bxlval.uval = BX_SEG_REG_ES; return(BX_TOKEN_ES); }
ss              { bxlval.uval = BX_SEG_REG_SS; return(BX_TOKEN_SS); }
ds              { bxlval.uval = BX_SEG_REG_DS; return(BX_TOKEN_DS); }
fs              { bxlval.uval = BX_SEG_REG_FS; return(BX_TOKEN_FS); }
gs              { bxlval.uval = BX_SEG_REG_GS; return(BX_TOKEN_GS); }
k[0-7]          { EVEX_OPMASK_REG(bxtext[1] - '0'); }
flags|eflags    { bxlval.uval = 0; return (BX_TOKEN_FLAGS); }
xml             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_XML); }
h|help          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_HELP); }
\?              |
calc            { bxlval.sval = strdup(bxtext); return(BX_TOKEN_CALC); }
addlyt          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_ADDLYT); }
remlyt          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_REMLYT); }
lyt             { bxlval.sval = strdup(bxtext); return(BX_TOKEN_LYT); }
source          { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SOURCE); }
<EXAMINE>\/[0-9]+                 { BEGIN(INITIAL); bxlval.sval = strdup(bxtext); return(BX_TOKEN_XFORMAT); }
<EXAMINE>\/[0-9]*[mxduotcsibhwg]+ { BEGIN(INITIAL); bxlval.sval = strdup(bxtext); return(BX_TOKEN_XFORMAT); }
<DISASM>\/[0-9]+        { BEGIN(INITIAL); bxlval.sval = strdup(bxtext); return(BX_TOKEN_DISFORMAT); }
"+"             { return ('+'); }
"-"             { return ('-'); }
"$"             { return (BX_TOKEN_DEREF_CHR); }
"*"             { return ('*'); }
"/"             { return ('/'); }
">>"            { return (BX_TOKEN_RSHIFT); }
"<<"            { return (BX_TOKEN_LSHIFT); }
"=="            { return (BX_TOKEN_EQ); }
"!="            { return (BX_TOKEN_NE); }
"<="            { return (BX_TOKEN_LE); }
">="            { return (BX_TOKEN_GE); }
">"             { return ('>'); }
"<"             { return ('<'); }
"&"             { return ('&'); }
"|"             { return ('|'); }
"^"             { return ('^'); }
"!"             { return ('!'); }
"@"             { return ('@'); }
"("             { return ('('); }
")"             { return (')'); }
\'([^\\\'\n]|(\\.))*\'    |       /* throw away leading and trailing \" */
\"([^\\\"\n]|(\\.))*\"    { bxlval.sval = strdup(bxtext+1); bxlval.sval[strlen(bxlval.sval)-1] = 0; return(BX_TOKEN_STRING); }
0x[0-9a-fA-F]+  { bxlval.uval = strtoull(bxtext, NULL, 16); return(BX_TOKEN_NUMERIC); }
0[0-7]+         { bxlval.uval = strtoull(bxtext, NULL, 8); return(BX_TOKEN_NUMERIC); }
[0-9]+          { bxlval.uval = strtoull(bxtext, NULL, 10); return(BX_TOKEN_NUMERIC); }
$[a-zA-Z_][a-zA-Z0-9_]* { bxlval.sval = strdup(bxtext); return(BX_TOKEN_SYMBOLNAME); }
[A-Za-z_][A-Za-z0-9_]*  { bxlval.sval = strdup(bxtext); return(BX_TOKEN_GENERIC); }
<*>";"          { return ('\n'); }
<*>\n           { return ('\n'); }
[#][^\n]*    ; // eat up comments '//'
.               { return(bxtext[0]); }
<EXAMINE,DISASM>. { BEGIN(INITIAL); unput(*bxtext); }
%%

  int
bx_yyinput(char *buf, int max_size)
{
  int len;

  if (lex_input_size == 0) {
    fprintf(stderr, "lex: no characters in string input buffer.\n");
    exit(1);
  }

  len = strlen(lex_input_ptr) + 1;
  if (len > max_size)
    len = max_size;

  memcpy(buf, lex_input_ptr, len);

  return(len);
}

  void
bx_add_lex_input(char *buf)
{
  lex_input_ptr  = buf;
  lex_input_size = strlen(buf);

  // Since we're parsing from strings, flush out
  // all current buffer state, so the next read
  // requests from yyinput

  bx_flush_buffer( YY_CURRENT_BUFFER );
}

#endif /* if BX_DEBUGGER */
