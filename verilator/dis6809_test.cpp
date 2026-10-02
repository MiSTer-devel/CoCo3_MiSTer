//============================================================================
//  dis6809 self-check.  `make distest`
//
//  Covers every addressing mode, both prefix pages, the register-list and
//  register-pair postbytes, and an undefined opcode. Cheap insurance: a
//  disassembler that is subtly wrong is worse than none, because it produces
//  confident output you will act on.
//============================================================================

#include "dis6809.h"
#include <cstdio>
#include <cstring>
static unsigned char M[0x10000];
static int rd(uint16_t a){ return M[a]; }
struct T { const char* bytes; const char* want; };
static int put(uint16_t a, const char* hex){ int n=0; while(*hex){ unsigned v; sscanf(hex,"%2x",&v); M[a+n++]=v; hex+=2; if(*hex==' ')hex++; } return n; }
int main(){
  T t[] = {
    {"20 09",            "BRA   $100b"},
    {"16 01 23",         "LBRA  $1126"},
    {"86 fd",            "LDA   #$fd"},
    {"10 ce fc 7f",      "LDS   #$fc7f"},
    {"1f 8b",            "TFR   A,DP"},
    {"1e 12",            "EXG   X,Y"},
    {"34 76",            "PSHS  A,B,X,Y,U"},
    {"35 ff",            "PULS  CC,A,B,DP,X,Y,U,PC"},
    {"36 40",            "PSHU  S"},
    {"d6 04",            "LDB   <$04"},
    {"be fb fe",         "LDX   $fbfe"},
    {"6e 84",            "JMP   ,X"},
    {"a6 80",            "LDA   ,X+"},
    {"a6 81",            "LDA   ,X++"},
    {"a6 82",            "LDA   ,-X"},
    {"a6 83",            "LDA   ,--X"},
    {"a6 91",            "LDA   [,X++]"},
    {"a6 a5",            "LDA   B,Y"},
    {"a6 c6",            "LDA   A,U"},
    {"a6 88 7f",         "LDA   $7f,X"},
    {"a6 89 12 34",      "LDA   $1234,X"},
    {"a6 9f 20 00",      "LDA   [$2000]"},
    {"a6 8c 10",         "LDA   $10,PCR"},
    {"a6 1f",            "LDA   -1,X"},
    {"a6 05",            "LDA   5,X"},
    {"e7 41",            "STB   1,U"},
    {"10 8e 12 34",      "LDY   #$1234"},
    {"11 83 00 01",      "CMPU  #$0001"},
    {"11 3f",            "SWI3"},
    {"39",               "RTS"},
    {"3d",               "MUL"},
    {"87",               "FCB   $87"},
  };
  int fail=0;
  for (auto& e : t) {
    memset(M,0,sizeof(M));
    int n = put(0x1000, e.bytes);
    char out[80];
    int len = dis6809(0x1000, rd, out, sizeof(out));
    bool ok = !strcmp(out, e.want) && (len==n || (!strcmp(e.want,"FCB   $87")));
    if(!ok){ printf("FAIL  %-16s got \"%s\" (len %d, expected %d) want \"%s\"\n", e.bytes,out,len,n,e.want); fail++; }
  }
  printf(fail? "%d FAILURES\n" : "all %d cases pass\n", fail?fail:(int)(sizeof(t)/sizeof(t[0])));
  return fail!=0;
}
