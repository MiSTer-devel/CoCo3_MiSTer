//============================================================================
//  Motorola 6809 disassembler
//
//  Table-driven, covering pages 1 ($xx), 2 ($10 xx) and 3 ($11 xx), all six
//  addressing modes and the full indexed postbyte set. No 6309 extensions --
//  rtl/mc6809i.v is a 6809, and silently decoding 6309 opcodes would hide the
//  fact that the CPU has run off into data.
//============================================================================

#include "dis6809.h"
#include <cstdio>
#include <cstring>

namespace {

enum Mode {
	INH,    // inherent
	IMM8,
	IMM16,
	DIR,
	EXT,
	IDX,
	REL8,
	REL16,
	RLIST_S,   // PSHS/PULS postbyte
	RLIST_U,   // PSHU/PULU postbyte
	REGPAIR,   // TFR/EXG postbyte
	ILL
};

struct Op { const char* name; Mode mode; };

// ---- page 1 ---------------------------------------------------------------
const Op page1[256] = {
/*00*/ {"NEG",DIR},{"?",ILL},{"?",ILL},{"COM",DIR},{"LSR",DIR},{"?",ILL},{"ROR",DIR},{"ASR",DIR},
/*08*/ {"LSL",DIR},{"ROL",DIR},{"DEC",DIR},{"?",ILL},{"INC",DIR},{"TST",DIR},{"JMP",DIR},{"CLR",DIR},
/*10*/ {"?",ILL},{"?",ILL},{"NOP",INH},{"SYNC",INH},{"?",ILL},{"?",ILL},{"LBRA",REL16},{"LBSR",REL16},
/*18*/ {"?",ILL},{"DAA",INH},{"ORCC",IMM8},{"?",ILL},{"ANDCC",IMM8},{"SEX",INH},{"EXG",REGPAIR},{"TFR",REGPAIR},
/*20*/ {"BRA",REL8},{"BRN",REL8},{"BHI",REL8},{"BLS",REL8},{"BCC",REL8},{"BCS",REL8},{"BNE",REL8},{"BEQ",REL8},
/*28*/ {"BVC",REL8},{"BVS",REL8},{"BPL",REL8},{"BMI",REL8},{"BGE",REL8},{"BLT",REL8},{"BGT",REL8},{"BLE",REL8},
/*30*/ {"LEAX",IDX},{"LEAY",IDX},{"LEAS",IDX},{"LEAU",IDX},{"PSHS",RLIST_S},{"PULS",RLIST_S},{"PSHU",RLIST_U},{"PULU",RLIST_U},
/*38*/ {"?",ILL},{"RTS",INH},{"ABX",INH},{"RTI",INH},{"CWAI",IMM8},{"MUL",INH},{"RESET",INH},{"SWI",INH},
/*40*/ {"NEGA",INH},{"?",ILL},{"?",ILL},{"COMA",INH},{"LSRA",INH},{"?",ILL},{"RORA",INH},{"ASRA",INH},
/*48*/ {"LSLA",INH},{"ROLA",INH},{"DECA",INH},{"?",ILL},{"INCA",INH},{"TSTA",INH},{"?",ILL},{"CLRA",INH},
/*50*/ {"NEGB",INH},{"?",ILL},{"?",ILL},{"COMB",INH},{"LSRB",INH},{"?",ILL},{"RORB",INH},{"ASRB",INH},
/*58*/ {"LSLB",INH},{"ROLB",INH},{"DECB",INH},{"?",ILL},{"INCB",INH},{"TSTB",INH},{"?",ILL},{"CLRB",INH},
/*60*/ {"NEG",IDX},{"?",ILL},{"?",ILL},{"COM",IDX},{"LSR",IDX},{"?",ILL},{"ROR",IDX},{"ASR",IDX},
/*68*/ {"LSL",IDX},{"ROL",IDX},{"DEC",IDX},{"?",ILL},{"INC",IDX},{"TST",IDX},{"JMP",IDX},{"CLR",IDX},
/*70*/ {"NEG",EXT},{"?",ILL},{"?",ILL},{"COM",EXT},{"LSR",EXT},{"?",ILL},{"ROR",EXT},{"ASR",EXT},
/*78*/ {"LSL",EXT},{"ROL",EXT},{"DEC",EXT},{"?",ILL},{"INC",EXT},{"TST",EXT},{"JMP",EXT},{"CLR",EXT},
/*80*/ {"SUBA",IMM8},{"CMPA",IMM8},{"SBCA",IMM8},{"SUBD",IMM16},{"ANDA",IMM8},{"BITA",IMM8},{"LDA",IMM8},{"?",ILL},
/*88*/ {"EORA",IMM8},{"ADCA",IMM8},{"ORA",IMM8},{"ADDA",IMM8},{"CMPX",IMM16},{"BSR",REL8},{"LDX",IMM16},{"?",ILL},
/*90*/ {"SUBA",DIR},{"CMPA",DIR},{"SBCA",DIR},{"SUBD",DIR},{"ANDA",DIR},{"BITA",DIR},{"LDA",DIR},{"STA",DIR},
/*98*/ {"EORA",DIR},{"ADCA",DIR},{"ORA",DIR},{"ADDA",DIR},{"CMPX",DIR},{"JSR",DIR},{"LDX",DIR},{"STX",DIR},
/*A0*/ {"SUBA",IDX},{"CMPA",IDX},{"SBCA",IDX},{"SUBD",IDX},{"ANDA",IDX},{"BITA",IDX},{"LDA",IDX},{"STA",IDX},
/*A8*/ {"EORA",IDX},{"ADCA",IDX},{"ORA",IDX},{"ADDA",IDX},{"CMPX",IDX},{"JSR",IDX},{"LDX",IDX},{"STX",IDX},
/*B0*/ {"SUBA",EXT},{"CMPA",EXT},{"SBCA",EXT},{"SUBD",EXT},{"ANDA",EXT},{"BITA",EXT},{"LDA",EXT},{"STA",EXT},
/*B8*/ {"EORA",EXT},{"ADCA",EXT},{"ORA",EXT},{"ADDA",EXT},{"CMPX",EXT},{"JSR",EXT},{"LDX",EXT},{"STX",EXT},
/*C0*/ {"SUBB",IMM8},{"CMPB",IMM8},{"SBCB",IMM8},{"ADDD",IMM16},{"ANDB",IMM8},{"BITB",IMM8},{"LDB",IMM8},{"?",ILL},
/*C8*/ {"EORB",IMM8},{"ADCB",IMM8},{"ORB",IMM8},{"ADDB",IMM8},{"LDD",IMM16},{"?",ILL},{"LDU",IMM16},{"?",ILL},
/*D0*/ {"SUBB",DIR},{"CMPB",DIR},{"SBCB",DIR},{"ADDD",DIR},{"ANDB",DIR},{"BITB",DIR},{"LDB",DIR},{"STB",DIR},
/*D8*/ {"EORB",DIR},{"ADCB",DIR},{"ORB",DIR},{"ADDB",DIR},{"LDD",DIR},{"STD",DIR},{"LDU",DIR},{"STU",DIR},
/*E0*/ {"SUBB",IDX},{"CMPB",IDX},{"SBCB",IDX},{"ADDD",IDX},{"ANDB",IDX},{"BITB",IDX},{"LDB",IDX},{"STB",IDX},
/*E8*/ {"EORB",IDX},{"ADCB",IDX},{"ORB",IDX},{"ADDB",IDX},{"LDD",IDX},{"STD",IDX},{"LDU",IDX},{"STU",IDX},
/*F0*/ {"SUBB",EXT},{"CMPB",EXT},{"SBCB",EXT},{"ADDD",EXT},{"ANDB",EXT},{"BITB",EXT},{"LDB",EXT},{"STB",EXT},
/*F8*/ {"EORB",EXT},{"ADCB",EXT},{"ORB",EXT},{"ADDB",EXT},{"LDD",EXT},{"STD",EXT},{"LDU",EXT},{"STU",EXT},
};

// ---- page 2 ($10 prefix) --------------------------------------------------
Op page2_lookup(uint8_t op) {
	switch (op) {
		case 0x21: return {"LBRN",REL16};  case 0x22: return {"LBHI",REL16};
		case 0x23: return {"LBLS",REL16};  case 0x24: return {"LBCC",REL16};
		case 0x25: return {"LBCS",REL16};  case 0x26: return {"LBNE",REL16};
		case 0x27: return {"LBEQ",REL16};  case 0x28: return {"LBVC",REL16};
		case 0x29: return {"LBVS",REL16};  case 0x2a: return {"LBPL",REL16};
		case 0x2b: return {"LBMI",REL16};  case 0x2c: return {"LBGE",REL16};
		case 0x2d: return {"LBLT",REL16};  case 0x2e: return {"LBGT",REL16};
		case 0x2f: return {"LBLE",REL16};
		case 0x3f: return {"SWI2",INH};
		case 0x83: return {"CMPD",IMM16};  case 0x8c: return {"CMPY",IMM16};
		case 0x8e: return {"LDY",IMM16};
		case 0x93: return {"CMPD",DIR};    case 0x9c: return {"CMPY",DIR};
		case 0x9e: return {"LDY",DIR};     case 0x9f: return {"STY",DIR};
		case 0xa3: return {"CMPD",IDX};    case 0xac: return {"CMPY",IDX};
		case 0xae: return {"LDY",IDX};     case 0xaf: return {"STY",IDX};
		case 0xb3: return {"CMPD",EXT};    case 0xbc: return {"CMPY",EXT};
		case 0xbe: return {"LDY",EXT};     case 0xbf: return {"STY",EXT};
		case 0xce: return {"LDS",IMM16};
		case 0xde: return {"LDS",DIR};     case 0xdf: return {"STS",DIR};
		case 0xee: return {"LDS",IDX};     case 0xef: return {"STS",IDX};
		case 0xfe: return {"LDS",EXT};     case 0xff: return {"STS",EXT};
		default:   return {"?",ILL};
	}
}

// ---- page 3 ($11 prefix) --------------------------------------------------
Op page3_lookup(uint8_t op) {
	switch (op) {
		case 0x3f: return {"SWI3",INH};
		case 0x83: return {"CMPU",IMM16};  case 0x8c: return {"CMPS",IMM16};
		case 0x93: return {"CMPU",DIR};    case 0x9c: return {"CMPS",DIR};
		case 0xa3: return {"CMPU",IDX};    case 0xac: return {"CMPS",IDX};
		case 0xb3: return {"CMPU",EXT};    case 0xbc: return {"CMPS",EXT};
		default:   return {"?",ILL};
	}
}

const char* const IDX_REG[4] = { "X", "Y", "U", "S" };

// TFR/EXG register field. 6809 leaves 6,7 and 12..15 undefined.
const char* const TFR_REG[16] = {
	"D","X","Y","U","S","PC","?6","?7","A","B","CC","DP","?c","?d","?e","?f"
};

void reg_list(uint8_t pb, bool is_u, char* out, size_t n) {
	static const char* names_s[8] = {"CC","A","B","DP","X","Y","U","PC"};
	static const char* names_u[8] = {"CC","A","B","DP","X","Y","S","PC"};
	const char* const* names = is_u ? names_u : names_s;
	out[0] = 0;
	size_t len = 0;
	for (int i = 0; i < 8; i++) {
		if (!(pb & (1 << i))) continue;
		int w = snprintf(out + len, n - len, "%s%s", len ? "," : "", names[i]);
		if (w < 0 || (size_t)w >= n - len) break;
		len += w;
	}
	if (!len) snprintf(out, n, "#$%02x", pb);
}

} // namespace

void cc6809_string(uint8_t cc, char out[9]) {
	static const char* bits = "EFHINZVC";   // bit 7 .. bit 0
	for (int i = 0; i < 8; i++) {
		char c = bits[i];
		out[i] = (cc & (0x80 >> i)) ? c : (char)(c + 32);
	}
	out[8] = 0;
}

int dis6809(uint16_t pc, int (*rd)(uint16_t), char* out, size_t outlen) {
	// Local fetch helpers. `bad` sticks once any byte of the instruction is
	// unknown, so the caller sees "??" rather than a plausible-looking lie.
	int  len = 0;
	bool bad = false;
	auto fetch = [&](void) -> int {
		int v = rd((uint16_t)(pc + len));
		len++;
		if (v < 0) { bad = true; return 0; }
		return v;
	};

	int op = fetch();
	Op o;
	if (bad) { snprintf(out, outlen, "??"); return 1; }

	if (op == 0x10)      { int o2 = fetch(); o = bad ? Op{"?",ILL} : page2_lookup((uint8_t)o2); }
	else if (op == 0x11) { int o2 = fetch(); o = bad ? Op{"?",ILL} : page3_lookup((uint8_t)o2); }
	else                 o = page1[op];

	if (o.mode == ILL) {
		snprintf(out, outlen, "FCB   $%02x", op);
		return 1;
	}

	char arg[64] = "";

	switch (o.mode) {
	case INH:
		break;
	case IMM8:  { int v = fetch(); snprintf(arg, sizeof(arg), "#$%02x", v); break; }
	case IMM16: { int h = fetch(), l = fetch(); snprintf(arg, sizeof(arg), "#$%02x%02x", h, l); break; }
	case DIR:   { int v = fetch(); snprintf(arg, sizeof(arg), "<$%02x", v); break; }
	case EXT:   { int h = fetch(), l = fetch(); snprintf(arg, sizeof(arg), "$%02x%02x", h, l); break; }
	case REL8:  { int v = fetch();
	              uint16_t dst = (uint16_t)(pc + len + (int8_t)v);
	              snprintf(arg, sizeof(arg), "$%04x", dst); break; }
	case REL16: { int h = fetch(), l = fetch();
	              uint16_t dst = (uint16_t)(pc + len + (int16_t)((h << 8) | l));
	              snprintf(arg, sizeof(arg), "$%04x", dst); break; }
	case RLIST_S: { int pb = fetch(); reg_list((uint8_t)pb, false, arg, sizeof(arg)); break; }
	case RLIST_U: { int pb = fetch(); reg_list((uint8_t)pb, true,  arg, sizeof(arg)); break; }
	case REGPAIR: { int pb = fetch();
	                snprintf(arg, sizeof(arg), "%s,%s", TFR_REG[(pb >> 4) & 15], TFR_REG[pb & 15]);
	                break; }
	case IDX: {
		int pb = fetch();
		const char* r = IDX_REG[(pb >> 5) & 3];
		if (!(pb & 0x80)) {
			// 5-bit signed offset, no indirect form
			int off = pb & 0x1f;
			if (off & 0x10) off -= 0x20;
			snprintf(arg, sizeof(arg), "%d,%s", off, r);
			break;
		}
		bool ind = (pb & 0x10) != 0;
		char body[48];
		switch (pb & 0x0f) {
		case 0x0: snprintf(body, sizeof(body), ",%s+", r); break;
		case 0x1: snprintf(body, sizeof(body), ",%s++", r); break;
		case 0x2: snprintf(body, sizeof(body), ",-%s", r); break;
		case 0x3: snprintf(body, sizeof(body), ",--%s", r); break;
		case 0x4: snprintf(body, sizeof(body), ",%s", r); break;
		case 0x5: snprintf(body, sizeof(body), "B,%s", r); break;
		case 0x6: snprintf(body, sizeof(body), "A,%s", r); break;
		case 0x8: { int v = fetch(); snprintf(body, sizeof(body), "$%02x,%s", v, r); break; }
		case 0x9: { int h = fetch(), l = fetch();
		            snprintf(body, sizeof(body), "$%02x%02x,%s", h, l, r); break; }
		case 0xb: snprintf(body, sizeof(body), "D,%s", r); break;
		case 0xc: { int v = fetch();
		            // PCR offsets are relative to the byte after the instruction,
		            // which is only known once the whole thing is decoded -- so
		            // print the raw offset and let the target be inferred.
		            snprintf(body, sizeof(body), "$%02x,PCR", v); break; }
		case 0xd: { int h = fetch(), l = fetch();
		            snprintf(body, sizeof(body), "$%02x%02x,PCR", h, l); break; }
		case 0xf: { int h = fetch(), l = fetch();
		            snprintf(body, sizeof(body), "$%02x%02x", h, l); break; }
		default:  snprintf(body, sizeof(body), "?pb$%02x,%s", pb, r); break;
		}
		if (ind) snprintf(arg, sizeof(arg), "[%s]", body);
		else     snprintf(arg, sizeof(arg), "%s", body);
		break;
	}
	default: break;
	}

	if (bad)          snprintf(out, outlen, "%-5s ??", o.name);
	else if (arg[0])  snprintf(out, outlen, "%-5s %s", o.name, arg);
	else              snprintf(out, outlen, "%s", o.name);
	return len ? len : 1;
}
