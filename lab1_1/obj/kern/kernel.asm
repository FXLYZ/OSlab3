
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 b0 ee 17 f0       	mov    $0xf017eeb0,%eax
f010004b:	2d 9d df 17 f0       	sub    $0xf017df9d,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 9d df 17 f0 	movl   $0xf017df9d,(%esp)
f0100063:	e8 5f 4d 00 00       	call   f0104dc7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b2 04 00 00       	call   f010051f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 52 10 f0 	movl   $0xf0105260,(%esp)
f010007c:	e8 42 39 00 00       	call   f01039c3 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 60 13 00 00       	call   f01013e6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 9b 32 00 00       	call   f0103326 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 a8 39 00 00       	call   f0103a3d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 56 c3 11 f0 	movl   $0xf011c356,(%esp)
f01000a4:	e8 6d 34 00 00       	call   f0103516 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 ec e1 17 f0       	mov    0xf017e1ec,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 31 38 00 00       	call   f01038e7 <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d a0 ee 17 f0 00 	cmpl   $0x0,0xf017eea0
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 a0 ee 17 f0    	mov    %esi,0xf017eea0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 7b 52 10 f0 	movl   $0xf010527b,(%esp)
f01000ea:	e8 d4 38 00 00       	call   f01039c3 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 95 38 00 00       	call   f0103990 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 65 55 10 f0 	movl   $0xf0105565,(%esp)
f0100102:	e8 bc 38 00 00       	call   f01039c3 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 88 08 00 00       	call   f010099b <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 93 52 10 f0 	movl   $0xf0105293,(%esp)
f0100134:	e8 8a 38 00 00       	call   f01039c3 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 48 38 00 00       	call   f0103990 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 65 55 10 f0 	movl   $0xf0105565,(%esp)
f010014f:	e8 6f 38 00 00       	call   f01039c3 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 c4 e1 17 f0       	mov    0xf017e1c4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d c4 e1 17 f0    	mov    %ecx,0xf017e1c4
f0100199:	88 90 c0 df 17 f0    	mov    %dl,-0xfe82040(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 c4 e1 17 f0 00 	movl   $0x0,0xf017e1c4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 ef 00 00 00    	je     f01002bd <kbd_proc_data+0xfd>
f01001ce:	b2 60                	mov    $0x60,%dl
f01001d0:	ec                   	in     (%dx),%al
f01001d1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d3:	3c e0                	cmp    $0xe0,%al
f01001d5:	75 0d                	jne    f01001e4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001d7:	83 0d a0 df 17 f0 40 	orl    $0x40,0xf017dfa0
		return 0;
f01001de:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001e3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e4:	55                   	push   %ebp
f01001e5:	89 e5                	mov    %esp,%ebp
f01001e7:	53                   	push   %ebx
f01001e8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 37                	jns    f0100226 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d a0 df 17 f0    	mov    0xf017dfa0,%ecx
f01001f5:	89 cb                	mov    %ecx,%ebx
f01001f7:	83 e3 40             	and    $0x40,%ebx
f01001fa:	83 e0 7f             	and    $0x7f,%eax
f01001fd:	85 db                	test   %ebx,%ebx
f01001ff:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100202:	0f b6 d2             	movzbl %dl,%edx
f0100205:	0f b6 82 00 54 10 f0 	movzbl -0xfefac00(%edx),%eax
f010020c:	83 c8 40             	or     $0x40,%eax
f010020f:	0f b6 c0             	movzbl %al,%eax
f0100212:	f7 d0                	not    %eax
f0100214:	21 c1                	and    %eax,%ecx
f0100216:	89 0d a0 df 17 f0    	mov    %ecx,0xf017dfa0
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 9d 00 00 00       	jmp    f01002c3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100226:	8b 0d a0 df 17 f0    	mov    0xf017dfa0,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d a0 df 17 f0    	mov    %ecx,0xf017dfa0
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
f0100242:	0f b6 82 00 54 10 f0 	movzbl -0xfefac00(%edx),%eax
f0100249:	0b 05 a0 df 17 f0    	or     0xf017dfa0,%eax
	shift ^= togglecode[data];
f010024f:	0f b6 8a 00 53 10 f0 	movzbl -0xfefad00(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 a0 df 17 f0       	mov    %eax,0xf017dfa0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d e0 52 10 f0 	mov    -0xfefad20(,%ecx,4),%ecx
f0100269:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010026d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100270:	a8 08                	test   $0x8,%al
f0100272:	74 1b                	je     f010028f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100274:	89 da                	mov    %ebx,%edx
f0100276:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100279:	83 f9 19             	cmp    $0x19,%ecx
f010027c:	77 05                	ja     f0100283 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010027e:	83 eb 20             	sub    $0x20,%ebx
f0100281:	eb 0c                	jmp    f010028f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 19             	cmp    $0x19,%edx
f010028c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028f:	f7 d0                	not    %eax
f0100291:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100293:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100295:	f6 c2 06             	test   $0x6,%dl
f0100298:	75 29                	jne    f01002c3 <kbd_proc_data+0x103>
f010029a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a0:	75 21                	jne    f01002c3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002a2:	c7 04 24 ad 52 10 f0 	movl   $0xf01052ad,(%esp)
f01002a9:	e8 15 37 00 00       	call   f01039c3 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ae:	ba 92 00 00 00       	mov    $0x92,%edx
f01002b3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b9:	89 d8                	mov    %ebx,%eax
f01002bb:	eb 06                	jmp    f01002c3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002c2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002c3:	83 c4 14             	add    $0x14,%esp
f01002c6:	5b                   	pop    %ebx
f01002c7:	5d                   	pop    %ebp
f01002c8:	c3                   	ret    

f01002c9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002c9:	55                   	push   %ebp
f01002ca:	89 e5                	mov    %esp,%ebp
f01002cc:	57                   	push   %edi
f01002cd:	56                   	push   %esi
f01002ce:	53                   	push   %ebx
f01002cf:	83 ec 1c             	sub    $0x1c,%esp
f01002d2:	89 c7                	mov    %eax,%edi
f01002d4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002de:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e3:	eb 06                	jmp    f01002eb <cons_putc+0x22>
f01002e5:	89 ca                	mov    %ecx,%edx
f01002e7:	ec                   	in     (%dx),%al
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	89 f2                	mov    %esi,%edx
f01002ed:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ee:	a8 20                	test   $0x20,%al
f01002f0:	75 05                	jne    f01002f7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f2:	83 eb 01             	sub    $0x1,%ebx
f01002f5:	75 ee                	jne    f01002e5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002f7:	89 f8                	mov    %edi,%eax
f01002f9:	0f b6 c0             	movzbl %al,%eax
f01002fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100304:	ee                   	out    %al,(%dx)
f0100305:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030a:	be 79 03 00 00       	mov    $0x379,%esi
f010030f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100314:	eb 06                	jmp    f010031c <cons_putc+0x53>
f0100316:	89 ca                	mov    %ecx,%edx
f0100318:	ec                   	in     (%dx),%al
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	89 f2                	mov    %esi,%edx
f010031e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010031f:	84 c0                	test   %al,%al
f0100321:	78 05                	js     f0100328 <cons_putc+0x5f>
f0100323:	83 eb 01             	sub    $0x1,%ebx
f0100326:	75 ee                	jne    f0100316 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100328:	ba 78 03 00 00       	mov    $0x378,%edx
f010032d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100331:	ee                   	out    %al,(%dx)
f0100332:	b2 7a                	mov    $0x7a,%dl
f0100334:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100339:	ee                   	out    %al,(%dx)
f010033a:	b8 08 00 00 00       	mov    $0x8,%eax
f010033f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100340:	89 fa                	mov    %edi,%edx
f0100342:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100348:	89 f8                	mov    %edi,%eax
f010034a:	80 cc 07             	or     $0x7,%ah
f010034d:	85 d2                	test   %edx,%edx
f010034f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	0f b6 c0             	movzbl %al,%eax
f0100357:	83 f8 09             	cmp    $0x9,%eax
f010035a:	74 76                	je     f01003d2 <cons_putc+0x109>
f010035c:	83 f8 09             	cmp    $0x9,%eax
f010035f:	7f 0a                	jg     f010036b <cons_putc+0xa2>
f0100361:	83 f8 08             	cmp    $0x8,%eax
f0100364:	74 16                	je     f010037c <cons_putc+0xb3>
f0100366:	e9 9b 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
f010036b:	83 f8 0a             	cmp    $0xa,%eax
f010036e:	66 90                	xchg   %ax,%ax
f0100370:	74 3a                	je     f01003ac <cons_putc+0xe3>
f0100372:	83 f8 0d             	cmp    $0xd,%eax
f0100375:	74 3d                	je     f01003b4 <cons_putc+0xeb>
f0100377:	e9 8a 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010037c:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f0100383:	66 85 c0             	test   %ax,%ax
f0100386:	0f 84 e5 00 00 00    	je     f0100471 <cons_putc+0x1a8>
			crt_pos--;
f010038c:	83 e8 01             	sub    $0x1,%eax
f010038f:	66 a3 c8 e1 17 f0    	mov    %ax,0xf017e1c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100395:	0f b7 c0             	movzwl %ax,%eax
f0100398:	66 81 e7 00 ff       	and    $0xff00,%di
f010039d:	83 cf 20             	or     $0x20,%edi
f01003a0:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
f01003a6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003aa:	eb 78                	jmp    f0100424 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ac:	66 83 05 c8 e1 17 f0 	addw   $0x50,0xf017e1c8
f01003b3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b4:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f01003bb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c1:	c1 e8 16             	shr    $0x16,%eax
f01003c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c7:	c1 e0 04             	shl    $0x4,%eax
f01003ca:	66 a3 c8 e1 17 f0    	mov    %ax,0xf017e1c8
f01003d0:	eb 52                	jmp    f0100424 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 ed fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e1:	e8 e3 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003eb:	e8 d9 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f5:	e8 cf fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ff:	e8 c5 fe ff ff       	call   f01002c9 <cons_putc>
f0100404:	eb 1e                	jmp    f0100424 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100406:	0f b7 05 c8 e1 17 f0 	movzwl 0xf017e1c8,%eax
f010040d:	8d 50 01             	lea    0x1(%eax),%edx
f0100410:	66 89 15 c8 e1 17 f0 	mov    %dx,0xf017e1c8
f0100417:	0f b7 c0             	movzwl %ax,%eax
f010041a:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
f0100420:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100424:	66 81 3d c8 e1 17 f0 	cmpw   $0x7cf,0xf017e1c8
f010042b:	cf 07 
f010042d:	76 42                	jbe    f0100471 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042f:	a1 cc e1 17 f0       	mov    0xf017e1cc,%eax
f0100434:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043b:	00 
f010043c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100442:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100446:	89 04 24             	mov    %eax,(%esp)
f0100449:	e8 c6 49 00 00       	call   f0104e14 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044e:	8b 15 cc e1 17 f0    	mov    0xf017e1cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100454:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100459:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045f:	83 c0 01             	add    $0x1,%eax
f0100462:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100467:	75 f0                	jne    f0100459 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100469:	66 83 2d c8 e1 17 f0 	subw   $0x50,0xf017e1c8
f0100470:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100471:	8b 0d d0 e1 17 f0    	mov    0xf017e1d0,%ecx
f0100477:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047f:	0f b7 1d c8 e1 17 f0 	movzwl 0xf017e1c8,%ebx
f0100486:	8d 71 01             	lea    0x1(%ecx),%esi
f0100489:	89 d8                	mov    %ebx,%eax
f010048b:	66 c1 e8 08          	shr    $0x8,%ax
f010048f:	89 f2                	mov    %esi,%edx
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100497:	89 ca                	mov    %ecx,%edx
f0100499:	ee                   	out    %al,(%dx)
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049f:	83 c4 1c             	add    $0x1c,%esp
f01004a2:	5b                   	pop    %ebx
f01004a3:	5e                   	pop    %esi
f01004a4:	5f                   	pop    %edi
f01004a5:	5d                   	pop    %ebp
f01004a6:	c3                   	ret    

f01004a7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a7:	80 3d d4 e1 17 f0 00 	cmpb   $0x0,0xf017e1d4
f01004ae:	74 11                	je     f01004c1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004bb:	e8 bc fc ff ff       	call   f010017c <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	f3 c3                	repz ret 

f01004c3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004ce:	e8 a9 fc ff ff       	call   f010017c <cons_intr>
}
f01004d3:	c9                   	leave  
f01004d4:	c3                   	ret    

f01004d5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d5:	55                   	push   %ebp
f01004d6:	89 e5                	mov    %esp,%ebp
f01004d8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004db:	e8 c7 ff ff ff       	call   f01004a7 <serial_intr>
	kbd_intr();
f01004e0:	e8 de ff ff ff       	call   f01004c3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e5:	a1 c0 e1 17 f0       	mov    0xf017e1c0,%eax
f01004ea:	3b 05 c4 e1 17 f0    	cmp    0xf017e1c4,%eax
f01004f0:	74 26                	je     f0100518 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f2:	8d 50 01             	lea    0x1(%eax),%edx
f01004f5:	89 15 c0 e1 17 f0    	mov    %edx,0xf017e1c0
f01004fb:	0f b6 88 c0 df 17 f0 	movzbl -0xfe82040(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100502:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100504:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010050a:	75 11                	jne    f010051d <cons_getc+0x48>
			cons.rpos = 0;
f010050c:	c7 05 c0 e1 17 f0 00 	movl   $0x0,0xf017e1c0
f0100513:	00 00 00 
f0100516:	eb 05                	jmp    f010051d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100518:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051d:	c9                   	leave  
f010051e:	c3                   	ret    

f010051f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	57                   	push   %edi
f0100523:	56                   	push   %esi
f0100524:	53                   	push   %ebx
f0100525:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100528:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100536:	5a a5 
	if (*cp != 0xA55A) {
f0100538:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100543:	74 11                	je     f0100556 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100545:	c7 05 d0 e1 17 f0 b4 	movl   $0x3b4,0xf017e1d0
f010054c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100554:	eb 16                	jmp    f010056c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100556:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055d:	c7 05 d0 e1 17 f0 d4 	movl   $0x3d4,0xf017e1d0
f0100564:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100567:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010056c:	8b 0d d0 e1 17 f0    	mov    0xf017e1d0,%ecx
f0100572:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100577:	89 ca                	mov    %ecx,%edx
f0100579:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010057a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057d:	89 da                	mov    %ebx,%edx
f010057f:	ec                   	in     (%dx),%al
f0100580:	0f b6 f0             	movzbl %al,%esi
f0100583:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100586:	b8 0f 00 00 00       	mov    $0xf,%eax
f010058b:	89 ca                	mov    %ecx,%edx
f010058d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058e:	89 da                	mov    %ebx,%edx
f0100590:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100591:	89 3d cc e1 17 f0    	mov    %edi,0xf017e1cc

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100597:	0f b6 d8             	movzbl %al,%ebx
f010059a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010059c:	66 89 35 c8 e1 17 f0 	mov    %si,0xf017e1c8
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ad:	89 f2                	mov    %esi,%edx
f01005af:	ee                   	out    %al,(%dx)
f01005b0:	b2 fb                	mov    $0xfb,%dl
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fb                	mov    $0xfb,%dl
f01005cf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 fc                	mov    $0xfc,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 f9                	mov    $0xf9,%dl
f01005df:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e5:	b2 fd                	mov    $0xfd,%dl
f01005e7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e8:	3c ff                	cmp    $0xff,%al
f01005ea:	0f 95 c1             	setne  %cl
f01005ed:	88 0d d4 e1 17 f0    	mov    %cl,0xf017e1d4
f01005f3:	89 f2                	mov    %esi,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	89 da                	mov    %ebx,%edx
f01005f8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f9:	84 c9                	test   %cl,%cl
f01005fb:	75 0c                	jne    f0100609 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fd:	c7 04 24 b9 52 10 f0 	movl   $0xf01052b9,(%esp)
f0100604:	e8 ba 33 00 00       	call   f01039c3 <cprintf>
}
f0100609:	83 c4 1c             	add    $0x1c,%esp
f010060c:	5b                   	pop    %ebx
f010060d:	5e                   	pop    %esi
f010060e:	5f                   	pop    %edi
f010060f:	5d                   	pop    %ebp
f0100610:	c3                   	ret    

f0100611 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100617:	8b 45 08             	mov    0x8(%ebp),%eax
f010061a:	e8 aa fc ff ff       	call   f01002c9 <cons_putc>
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <getchar>:

int
getchar(void)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100627:	e8 a9 fe ff ff       	call   f01004d5 <cons_getc>
f010062c:	85 c0                	test   %eax,%eax
f010062e:	74 f7                	je     f0100627 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100630:	c9                   	leave  
f0100631:	c3                   	ret    

f0100632 <iscons>:

int
iscons(int fdnum)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100635:	b8 01 00 00 00       	mov    $0x1,%eax
f010063a:	5d                   	pop    %ebp
f010063b:	c3                   	ret    
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 10             	sub    $0x10,%esp
f0100648:	bb 84 58 10 f0       	mov    $0xf0105884,%ebx
f010064d:	be b4 58 10 f0       	mov    $0xf01058b4,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100652:	8b 03                	mov    (%ebx),%eax
f0100654:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100658:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010065b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010065f:	c7 04 24 00 55 10 f0 	movl   $0xf0105500,(%esp)
f0100666:	e8 58 33 00 00       	call   f01039c3 <cprintf>
f010066b:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010066e:	39 f3                	cmp    %esi,%ebx
f0100670:	75 e0                	jne    f0100652 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100672:	b8 00 00 00 00       	mov    $0x0,%eax
f0100677:	83 c4 10             	add    $0x10,%esp
f010067a:	5b                   	pop    %ebx
f010067b:	5e                   	pop    %esi
f010067c:	5d                   	pop    %ebp
f010067d:	c3                   	ret    

f010067e <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067e:	55                   	push   %ebp
f010067f:	89 e5                	mov    %esp,%ebp
f0100681:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100684:	c7 04 24 09 55 10 f0 	movl   $0xf0105509,(%esp)
f010068b:	e8 33 33 00 00       	call   f01039c3 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100690:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100697:	00 
f0100698:	c7 04 24 5c 56 10 f0 	movl   $0xf010565c,(%esp)
f010069f:	e8 1f 33 00 00       	call   f01039c3 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a4:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ab:	00 
f01006ac:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b3:	f0 
f01006b4:	c7 04 24 84 56 10 f0 	movl   $0xf0105684,(%esp)
f01006bb:	e8 03 33 00 00       	call   f01039c3 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c0:	c7 44 24 08 57 52 10 	movl   $0x105257,0x8(%esp)
f01006c7:	00 
f01006c8:	c7 44 24 04 57 52 10 	movl   $0xf0105257,0x4(%esp)
f01006cf:	f0 
f01006d0:	c7 04 24 a8 56 10 f0 	movl   $0xf01056a8,(%esp)
f01006d7:	e8 e7 32 00 00       	call   f01039c3 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006dc:	c7 44 24 08 9d df 17 	movl   $0x17df9d,0x8(%esp)
f01006e3:	00 
f01006e4:	c7 44 24 04 9d df 17 	movl   $0xf017df9d,0x4(%esp)
f01006eb:	f0 
f01006ec:	c7 04 24 cc 56 10 f0 	movl   $0xf01056cc,(%esp)
f01006f3:	e8 cb 32 00 00       	call   f01039c3 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f8:	c7 44 24 08 b0 ee 17 	movl   $0x17eeb0,0x8(%esp)
f01006ff:	00 
f0100700:	c7 44 24 04 b0 ee 17 	movl   $0xf017eeb0,0x4(%esp)
f0100707:	f0 
f0100708:	c7 04 24 f0 56 10 f0 	movl   $0xf01056f0,(%esp)
f010070f:	e8 af 32 00 00       	call   f01039c3 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100714:	b8 af f2 17 f0       	mov    $0xf017f2af,%eax
f0100719:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f010071e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100723:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100729:	85 c0                	test   %eax,%eax
f010072b:	0f 48 c2             	cmovs  %edx,%eax
f010072e:	c1 f8 0a             	sar    $0xa,%eax
f0100731:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100735:	c7 04 24 14 57 10 f0 	movl   $0xf0105714,(%esp)
f010073c:	e8 82 32 00 00       	call   f01039c3 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100741:	b8 00 00 00 00       	mov    $0x0,%eax
f0100746:	c9                   	leave  
f0100747:	c3                   	ret    

f0100748 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
f010074b:	57                   	push   %edi
f010074c:	56                   	push   %esi
f010074d:	53                   	push   %ebx
f010074e:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
        cprintf("Stack backtrace:\n");
f0100751:	c7 04 24 22 55 10 f0 	movl   $0xf0105522,(%esp)
f0100758:	e8 66 32 00 00       	call   f01039c3 <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010075d:	89 ee                	mov    %ebp,%esi
	unsigned int ebp,esp,eip;
	ebp=read_ebp();
	while(ebp){
f010075f:	e9 8a 00 00 00       	jmp    f01007ee <mon_backtrace+0xa6>
		eip=*((unsigned int*)(ebp+4));
f0100764:	8d 5e 04             	lea    0x4(%esi),%ebx
f0100767:	8b 46 04             	mov    0x4(%esi),%eax
f010076a:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		esp=ebp+4;
		cprintf("  ebp %08x  eip %08x  args",ebp,eip);
f010076d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100771:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100775:	c7 04 24 34 55 10 f0 	movl   $0xf0105534,(%esp)
f010077c:	e8 42 32 00 00       	call   f01039c3 <cprintf>
f0100781:	8d 7e 18             	lea    0x18(%esi),%edi
                int i=0;
		for(i=0;i<5;i++)
		{
			esp+=4;
f0100784:	83 c3 04             	add    $0x4,%ebx
			cprintf(" %08x",*(unsigned int*)esp);
f0100787:	8b 03                	mov    (%ebx),%eax
f0100789:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078d:	c7 04 24 4f 55 10 f0 	movl   $0xf010554f,(%esp)
f0100794:	e8 2a 32 00 00       	call   f01039c3 <cprintf>
	while(ebp){
		eip=*((unsigned int*)(ebp+4));
		esp=ebp+4;
		cprintf("  ebp %08x  eip %08x  args",ebp,eip);
                int i=0;
		for(i=0;i<5;i++)
f0100799:	39 fb                	cmp    %edi,%ebx
f010079b:	75 e7                	jne    f0100784 <mon_backtrace+0x3c>
			esp+=4;
			cprintf(" %08x",*(unsigned int*)esp);
		}

                struct Eipdebuginfo info;
		debuginfo_eip(eip,&info);
f010079d:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a4:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01007a7:	89 3c 24             	mov    %edi,(%esp)
f01007aa:	e8 a3 3b 00 00       	call   f0104352 <debuginfo_eip>
                cprintf("\r\n");
f01007af:	c7 04 24 64 55 10 f0 	movl   $0xf0105564,(%esp)
f01007b6:	e8 08 32 00 00       	call   f01039c3 <cprintf>
		cprintf("\t%s:%d: %.*s+%u\r\n",info.eip_file,
f01007bb:	89 f8                	mov    %edi,%eax
f01007bd:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007c0:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007c7:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007ce:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e0:	c7 04 24 55 55 10 f0 	movl   $0xf0105555,(%esp)
f01007e7:	e8 d7 31 00 00       	call   f01039c3 <cprintf>
			info.eip_line,
			info.eip_fn_namelen,
			info.eip_fn_name,
			eip-info.eip_fn_addr); 

		ebp=*((unsigned int*)ebp);
f01007ec:	8b 36                	mov    (%esi),%esi
{
	// Your code here.
        cprintf("Stack backtrace:\n");
	unsigned int ebp,esp,eip;
	ebp=read_ebp();
	while(ebp){
f01007ee:	85 f6                	test   %esi,%esi
f01007f0:	0f 85 6e ff ff ff    	jne    f0100764 <mon_backtrace+0x1c>
			eip-info.eip_fn_addr); 

		ebp=*((unsigned int*)ebp);
	}
	return 0;
}
f01007f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01007fb:	83 c4 4c             	add    $0x4c,%esp
f01007fe:	5b                   	pop    %ebx
f01007ff:	5e                   	pop    %esi
f0100800:	5f                   	pop    %edi
f0100801:	5d                   	pop    %ebp
f0100802:	c3                   	ret    

f0100803 <mon_showmappings>:

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f0100803:	55                   	push   %ebp
f0100804:	89 e5                	mov    %esp,%ebp
f0100806:	57                   	push   %edi
f0100807:	56                   	push   %esi
f0100808:	53                   	push   %ebx
f0100809:	83 ec 2c             	sub    $0x2c,%esp
f010080c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// 参数检查
    if (argc != 3) {
f010080f:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100813:	74 16                	je     f010082b <mon_showmappings+0x28>
        cprintf("Requir 2 virtual address as arguments.\n");
f0100815:	c7 04 24 40 57 10 f0 	movl   $0xf0105740,(%esp)
f010081c:	e8 a2 31 00 00       	call   f01039c3 <cprintf>
        return -1;
f0100821:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100826:	e9 68 01 00 00       	jmp    f0100993 <mon_showmappings+0x190>
    }
    char *errChar;
    uintptr_t start_addr = strtol(argv[1], &errChar, 16);
f010082b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100832:	00 
f0100833:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100836:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083a:	8b 46 04             	mov    0x4(%esi),%eax
f010083d:	89 04 24             	mov    %eax,(%esp)
f0100840:	e8 ae 46 00 00       	call   f0104ef3 <strtol>
f0100845:	89 c3                	mov    %eax,%ebx
    if (*errChar) {
f0100847:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010084a:	80 38 00             	cmpb   $0x0,(%eax)
f010084d:	74 1d                	je     f010086c <mon_showmappings+0x69>
        cprintf("Invalid virtual address: %s.\n", argv[1]);
f010084f:	8b 46 04             	mov    0x4(%esi),%eax
f0100852:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100856:	c7 04 24 67 55 10 f0 	movl   $0xf0105567,(%esp)
f010085d:	e8 61 31 00 00       	call   f01039c3 <cprintf>
        return -1;
f0100862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100867:	e9 27 01 00 00       	jmp    f0100993 <mon_showmappings+0x190>
    }
    uintptr_t end_addr = strtol(argv[2], &errChar, 16);
f010086c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100873:	00 
f0100874:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100877:	89 44 24 04          	mov    %eax,0x4(%esp)
f010087b:	8b 46 08             	mov    0x8(%esi),%eax
f010087e:	89 04 24             	mov    %eax,(%esp)
f0100881:	e8 6d 46 00 00       	call   f0104ef3 <strtol>
    if (*errChar) {
f0100886:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100889:	80 3a 00             	cmpb   $0x0,(%edx)
f010088c:	74 1d                	je     f01008ab <mon_showmappings+0xa8>
        cprintf("Invalid virtual address: %s.\n", argv[2]);
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100895:	c7 04 24 67 55 10 f0 	movl   $0xf0105567,(%esp)
f010089c:	e8 22 31 00 00       	call   f01039c3 <cprintf>
        return -1;
f01008a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01008a6:	e9 e8 00 00 00       	jmp    f0100993 <mon_showmappings+0x190>
    }
    if (start_addr > end_addr) {
f01008ab:	39 c3                	cmp    %eax,%ebx
f01008ad:	76 16                	jbe    f01008c5 <mon_showmappings+0xc2>
        cprintf("Address 1 must be lower than address 2\n");
f01008af:	c7 04 24 68 57 10 f0 	movl   $0xf0105768,(%esp)
f01008b6:	e8 08 31 00 00       	call   f01039c3 <cprintf>
        return -1;
f01008bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01008c0:	e9 ce 00 00 00       	jmp    f0100993 <mon_showmappings+0x190>
    }
    
    // 按页对齐
    start_addr = ROUNDDOWN(start_addr, PGSIZE);
f01008c5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    end_addr = ROUNDUP(end_addr, PGSIZE);
f01008cb:	8d b8 ff 0f 00 00    	lea    0xfff(%eax),%edi
f01008d1:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

    // 开始循环
    uintptr_t cur_addr = start_addr;
    while (cur_addr <= end_addr) {
f01008d7:	e9 aa 00 00 00       	jmp    f0100986 <mon_showmappings+0x183>
        pte_t *cur_pte = pgdir_walk(kern_pgdir, (void *) cur_addr, 0);
f01008dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01008e3:	00 
f01008e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008e8:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 89 08 00 00       	call   f010117e <pgdir_walk>
f01008f5:	89 c6                	mov    %eax,%esi
        // 记录自己一个错误
        // if ( !cur_pte) {
        if ( !cur_pte || !(*cur_pte & PTE_P)) {
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	74 06                	je     f0100901 <mon_showmappings+0xfe>
f01008fb:	8b 00                	mov    (%eax),%eax
f01008fd:	a8 01                	test   $0x1,%al
f01008ff:	75 12                	jne    f0100913 <mon_showmappings+0x110>
            cprintf( "Virtual address [%08x] - not mapped\n", cur_addr);
f0100901:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100905:	c7 04 24 90 57 10 f0 	movl   $0xf0105790,(%esp)
f010090c:	e8 b2 30 00 00       	call   f01039c3 <cprintf>
f0100911:	eb 6d                	jmp    f0100980 <mon_showmappings+0x17d>
        } else {
            cprintf( "Virtual address [%08x] - physical address [%08x], permission: ", cur_addr, PTE_ADDR(*cur_pte));
f0100913:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100918:	89 44 24 08          	mov    %eax,0x8(%esp)
f010091c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100920:	c7 04 24 b8 57 10 f0 	movl   $0xf01057b8,(%esp)
f0100927:	e8 97 30 00 00       	call   f01039c3 <cprintf>
            char perm_PS = (*cur_pte & PTE_PS) ? 'S':'-';
f010092c:	8b 06                	mov    (%esi),%eax
f010092e:	89 c2                	mov    %eax,%edx
f0100930:	81 e2 80 00 00 00    	and    $0x80,%edx
f0100936:	83 fa 01             	cmp    $0x1,%edx
f0100939:	19 d2                	sbb    %edx,%edx
f010093b:	83 e2 da             	and    $0xffffffda,%edx
f010093e:	83 c2 53             	add    $0x53,%edx
            char perm_W = (*cur_pte & PTE_W) ? 'W':'-';
f0100941:	89 c1                	mov    %eax,%ecx
f0100943:	83 e1 02             	and    $0x2,%ecx
f0100946:	83 f9 01             	cmp    $0x1,%ecx
f0100949:	19 c9                	sbb    %ecx,%ecx
f010094b:	83 e1 d6             	and    $0xffffffd6,%ecx
f010094e:	83 c1 57             	add    $0x57,%ecx
            char perm_U = (*cur_pte & PTE_U) ? 'U':'-';
f0100951:	83 e0 04             	and    $0x4,%eax
f0100954:	83 f8 01             	cmp    $0x1,%eax
f0100957:	19 c0                	sbb    %eax,%eax
f0100959:	83 e0 d8             	and    $0xffffffd8,%eax
f010095c:	83 c0 55             	add    $0x55,%eax
            // 进入 else 分支说明 PTE_P 肯定为真了
            cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
f010095f:	0f be c9             	movsbl %cl,%ecx
f0100962:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100966:	0f be c0             	movsbl %al,%eax
f0100969:	89 44 24 08          	mov    %eax,0x8(%esp)
f010096d:	0f be d2             	movsbl %dl,%edx
f0100970:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100974:	c7 04 24 85 55 10 f0 	movl   $0xf0105585,(%esp)
f010097b:	e8 43 30 00 00       	call   f01039c3 <cprintf>
        }
        cur_addr += PGSIZE;
f0100980:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    start_addr = ROUNDDOWN(start_addr, PGSIZE);
    end_addr = ROUNDUP(end_addr, PGSIZE);

    // 开始循环
    uintptr_t cur_addr = start_addr;
    while (cur_addr <= end_addr) {
f0100986:	39 fb                	cmp    %edi,%ebx
f0100988:	0f 86 4e ff ff ff    	jbe    f01008dc <mon_showmappings+0xd9>
            // 进入 else 分支说明 PTE_P 肯定为真了
            cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
        }
        cur_addr += PGSIZE;
    }
    return 0;
f010098e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100993:	83 c4 2c             	add    $0x2c,%esp
f0100996:	5b                   	pop    %ebx
f0100997:	5e                   	pop    %esi
f0100998:	5f                   	pop    %edi
f0100999:	5d                   	pop    %ebp
f010099a:	c3                   	ret    

f010099b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010099b:	55                   	push   %ebp
f010099c:	89 e5                	mov    %esp,%ebp
f010099e:	57                   	push   %edi
f010099f:	56                   	push   %esi
f01009a0:	53                   	push   %ebx
f01009a1:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
        
        int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f01009a4:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01009ab:	00 
f01009ac:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f01009b3:	00 
f01009b4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01009bb:	00 
f01009bc:	c7 04 24 93 55 10 f0 	movl   $0xf0105593,(%esp)
f01009c3:	e8 fb 2f 00 00       	call   f01039c3 <cprintf>
	unsigned int i = 0x00646c72;
f01009c8:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
        cprintf("H%x Wo%s", 57616, &i);
f01009cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01009d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009d6:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f01009dd:	00 
f01009de:	c7 04 24 a5 55 10 f0 	movl   $0xf01055a5,(%esp)
f01009e5:	e8 d9 2f 00 00       	call   f01039c3 <cprintf>
        cprintf("\n");
f01009ea:	c7 04 24 65 55 10 f0 	movl   $0xf0105565,(%esp)
f01009f1:	e8 cd 2f 00 00       	call   f01039c3 <cprintf>

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009f6:	c7 04 24 f8 57 10 f0 	movl   $0xf01057f8,(%esp)
f01009fd:	e8 c1 2f 00 00       	call   f01039c3 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a02:	c7 04 24 1c 58 10 f0 	movl   $0xf010581c,(%esp)
f0100a09:	e8 b5 2f 00 00       	call   f01039c3 <cprintf>

	if (tf != NULL)
f0100a0e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100a12:	74 0b                	je     f0100a1f <monitor+0x84>
		print_trapframe(tf);
f0100a14:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a17:	89 04 24             	mov    %eax,(%esp)
f0100a1a:	e8 7f 33 00 00       	call   f0103d9e <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a1f:	c7 04 24 ae 55 10 f0 	movl   $0xf01055ae,(%esp)
f0100a26:	e8 45 41 00 00       	call   f0104b70 <readline>
f0100a2b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a2d:	85 c0                	test   %eax,%eax
f0100a2f:	74 ee                	je     f0100a1f <monitor+0x84>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100a31:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100a38:	be 00 00 00 00       	mov    $0x0,%esi
f0100a3d:	eb 0a                	jmp    f0100a49 <monitor+0xae>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100a3f:	c6 03 00             	movb   $0x0,(%ebx)
f0100a42:	89 f7                	mov    %esi,%edi
f0100a44:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a47:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a49:	0f b6 03             	movzbl (%ebx),%eax
f0100a4c:	84 c0                	test   %al,%al
f0100a4e:	74 64                	je     f0100ab4 <monitor+0x119>
f0100a50:	0f be c0             	movsbl %al,%eax
f0100a53:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a57:	c7 04 24 b2 55 10 f0 	movl   $0xf01055b2,(%esp)
f0100a5e:	e8 27 43 00 00       	call   f0104d8a <strchr>
f0100a63:	85 c0                	test   %eax,%eax
f0100a65:	75 d8                	jne    f0100a3f <monitor+0xa4>
			*buf++ = 0;
		if (*buf == 0)
f0100a67:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a6a:	74 48                	je     f0100ab4 <monitor+0x119>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a6c:	83 fe 0f             	cmp    $0xf,%esi
f0100a6f:	90                   	nop
f0100a70:	75 16                	jne    f0100a88 <monitor+0xed>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a72:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a79:	00 
f0100a7a:	c7 04 24 b7 55 10 f0 	movl   $0xf01055b7,(%esp)
f0100a81:	e8 3d 2f 00 00       	call   f01039c3 <cprintf>
f0100a86:	eb 97                	jmp    f0100a1f <monitor+0x84>
			return 0;
		}
		argv[argc++] = buf;
f0100a88:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a8b:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100a8f:	eb 03                	jmp    f0100a94 <monitor+0xf9>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a91:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a94:	0f b6 03             	movzbl (%ebx),%eax
f0100a97:	84 c0                	test   %al,%al
f0100a99:	74 ac                	je     f0100a47 <monitor+0xac>
f0100a9b:	0f be c0             	movsbl %al,%eax
f0100a9e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aa2:	c7 04 24 b2 55 10 f0 	movl   $0xf01055b2,(%esp)
f0100aa9:	e8 dc 42 00 00       	call   f0104d8a <strchr>
f0100aae:	85 c0                	test   %eax,%eax
f0100ab0:	74 df                	je     f0100a91 <monitor+0xf6>
f0100ab2:	eb 93                	jmp    f0100a47 <monitor+0xac>
			buf++;
	}
	argv[argc] = 0;
f0100ab4:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100abb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100abc:	85 f6                	test   %esi,%esi
f0100abe:	0f 84 5b ff ff ff    	je     f0100a1f <monitor+0x84>
f0100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ac9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100acc:	8b 04 85 80 58 10 f0 	mov    -0xfefa780(,%eax,4),%eax
f0100ad3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad7:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100ada:	89 04 24             	mov    %eax,(%esp)
f0100add:	e8 4a 42 00 00       	call   f0104d2c <strcmp>
f0100ae2:	85 c0                	test   %eax,%eax
f0100ae4:	75 24                	jne    f0100b0a <monitor+0x16f>
			return commands[i].func(argc, argv, tf);
f0100ae6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ae9:	8b 55 08             	mov    0x8(%ebp),%edx
f0100aec:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100af0:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
f0100af3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100af7:	89 34 24             	mov    %esi,(%esp)
f0100afa:	ff 14 85 88 58 10 f0 	call   *-0xfefa778(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100b01:	85 c0                	test   %eax,%eax
f0100b03:	78 25                	js     f0100b2a <monitor+0x18f>
f0100b05:	e9 15 ff ff ff       	jmp    f0100a1f <monitor+0x84>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100b0a:	83 c3 01             	add    $0x1,%ebx
f0100b0d:	83 fb 04             	cmp    $0x4,%ebx
f0100b10:	75 b7                	jne    f0100ac9 <monitor+0x12e>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b12:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100b15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b19:	c7 04 24 d4 55 10 f0 	movl   $0xf01055d4,(%esp)
f0100b20:	e8 9e 2e 00 00       	call   f01039c3 <cprintf>
f0100b25:	e9 f5 fe ff ff       	jmp    f0100a1f <monitor+0x84>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100b2a:	83 c4 6c             	add    $0x6c,%esp
f0100b2d:	5b                   	pop    %ebx
f0100b2e:	5e                   	pop    %esi
f0100b2f:	5f                   	pop    %edi
f0100b30:	5d                   	pop    %ebp
f0100b31:	c3                   	ret    
f0100b32:	66 90                	xchg   %ax,%ax
f0100b34:	66 90                	xchg   %ax,%ax
f0100b36:	66 90                	xchg   %ax,%ax
f0100b38:	66 90                	xchg   %ax,%ax
f0100b3a:	66 90                	xchg   %ax,%ax
f0100b3c:	66 90                	xchg   %ax,%ax
f0100b3e:	66 90                	xchg   %ax,%ax

f0100b40 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f0100b40:	83 3d d8 e1 17 f0 00 	cmpl   $0x0,0xf017e1d8
f0100b47:	75 11                	jne    f0100b5a <boot_alloc+0x1a>
	{
		extern char end[];
		nextfree = ROUNDUP((char *)end, PGSIZE);
f0100b49:	ba af fe 17 f0       	mov    $0xf017feaf,%edx
f0100b4e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b54:	89 15 d8 e1 17 f0    	mov    %edx,0xf017e1d8
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	result = nextfree;
f0100b5a:	8b 0d d8 e1 17 f0    	mov    0xf017e1d8,%ecx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100b60:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100b67:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b6d:	89 15 d8 e1 17 f0    	mov    %edx,0xf017e1d8
	if ((uint32_t)nextfree - KERNBASE > (npages * PGSIZE))
f0100b73:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100b79:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0100b7e:	c1 e0 0c             	shl    $0xc,%eax
f0100b81:	39 c2                	cmp    %eax,%edx
f0100b83:	76 22                	jbe    f0100ba7 <boot_alloc+0x67>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b85:	55                   	push   %ebp
f0100b86:	89 e5                	mov    %esp,%ebp
f0100b88:	83 ec 18             	sub    $0x18,%esp
	// LAB 2: Your code here.

	result = nextfree;
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
	if ((uint32_t)nextfree - KERNBASE > (npages * PGSIZE))
		panic("Out of memory!\n");
f0100b8b:	c7 44 24 08 b0 58 10 	movl   $0xf01058b0,0x8(%esp)
f0100b92:	f0 
f0100b93:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
f0100b9a:	00 
f0100b9b:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100ba2:	e8 0f f5 ff ff       	call   f01000b6 <_panic>
	return result;
}
f0100ba7:	89 c8                	mov    %ecx,%eax
f0100ba9:	c3                   	ret    

f0100baa <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100baa:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0100bb0:	c1 f8 03             	sar    $0x3,%eax
f0100bb3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb6:	89 c2                	mov    %eax,%edx
f0100bb8:	c1 ea 0c             	shr    $0xc,%edx
f0100bbb:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0100bc1:	72 26                	jb     f0100be9 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100bc3:	55                   	push   %ebp
f0100bc4:	89 e5                	mov    %esp,%ebp
f0100bc6:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bcd:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0100bd4:	f0 
f0100bd5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100bdc:	00 
f0100bdd:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f0100be4:	e8 cd f4 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100be9:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100bee:	c3                   	ret    

f0100bef <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bef:	89 d1                	mov    %edx,%ecx
f0100bf1:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100bf4:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100bf7:	a8 01                	test   $0x1,%al
f0100bf9:	74 5d                	je     f0100c58 <check_va2pa+0x69>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100bfb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c00:	89 c1                	mov    %eax,%ecx
f0100c02:	c1 e9 0c             	shr    $0xc,%ecx
f0100c05:	3b 0d a4 ee 17 f0    	cmp    0xf017eea4,%ecx
f0100c0b:	72 26                	jb     f0100c33 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c0d:	55                   	push   %ebp
f0100c0e:	89 e5                	mov    %esp,%ebp
f0100c10:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c13:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c17:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0100c1e:	f0 
f0100c1f:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0100c26:	00 
f0100c27:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100c2e:	e8 83 f4 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100c33:	c1 ea 0c             	shr    $0xc,%edx
f0100c36:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c3c:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100c43:	89 c2                	mov    %eax,%edx
f0100c45:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c4d:	85 d2                	test   %edx,%edx
f0100c4f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c54:	0f 44 c2             	cmove  %edx,%eax
f0100c57:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100c58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100c5d:	c3                   	ret    

f0100c5e <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c5e:	55                   	push   %ebp
f0100c5f:	89 e5                	mov    %esp,%ebp
f0100c61:	57                   	push   %edi
f0100c62:	56                   	push   %esi
f0100c63:	53                   	push   %ebx
f0100c64:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c67:	84 c0                	test   %al,%al
f0100c69:	0f 85 07 03 00 00    	jne    f0100f76 <check_page_free_list+0x318>
f0100c6f:	e9 14 03 00 00       	jmp    f0100f88 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c74:	c7 44 24 08 70 5b 10 	movl   $0xf0105b70,0x8(%esp)
f0100c7b:	f0 
f0100c7c:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0100c83:	00 
f0100c84:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100c8b:	e8 26 f4 ff ff       	call   f01000b6 <_panic>
	if (only_low_memory)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100c90:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c93:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c96:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c99:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c9c:	89 c2                	mov    %eax,%edx
f0100c9e:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link)
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ca4:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100caa:	0f 95 c2             	setne  %dl
f0100cad:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100cb0:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100cb4:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100cb6:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cba:	8b 00                	mov    (%eax),%eax
f0100cbc:	85 c0                	test   %eax,%eax
f0100cbe:	75 dc                	jne    f0100c9c <check_page_free_list+0x3e>
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100cc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cc3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100cc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ccc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ccf:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100cd1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cd4:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cd9:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cde:	8b 1d e0 e1 17 f0    	mov    0xf017e1e0,%ebx
f0100ce4:	eb 63                	jmp    f0100d49 <check_page_free_list+0xeb>
f0100ce6:	89 d8                	mov    %ebx,%eax
f0100ce8:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f0100cee:	c1 f8 03             	sar    $0x3,%eax
f0100cf1:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cf4:	89 c2                	mov    %eax,%edx
f0100cf6:	c1 ea 16             	shr    $0x16,%edx
f0100cf9:	39 f2                	cmp    %esi,%edx
f0100cfb:	73 4a                	jae    f0100d47 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfd:	89 c2                	mov    %eax,%edx
f0100cff:	c1 ea 0c             	shr    $0xc,%edx
f0100d02:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0100d08:	72 20                	jb     f0100d2a <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d0e:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0100d15:	f0 
f0100d16:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d1d:	00 
f0100d1e:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f0100d25:	e8 8c f3 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d2a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d31:	00 
f0100d32:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d39:	00 
	return (void *)(pa + KERNBASE);
f0100d3a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d3f:	89 04 24             	mov    %eax,(%esp)
f0100d42:	e8 80 40 00 00       	call   f0104dc7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d47:	8b 1b                	mov    (%ebx),%ebx
f0100d49:	85 db                	test   %ebx,%ebx
f0100d4b:	75 99                	jne    f0100ce6 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
f0100d4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d52:	e8 e9 fd ff ff       	call   f0100b40 <boot_alloc>
f0100d57:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d5a:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d60:	8b 0d ac ee 17 f0    	mov    0xf017eeac,%ecx
		assert(pp < pages + npages);
f0100d66:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0100d6b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d6e:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100d74:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d77:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d7c:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d7f:	e9 97 01 00 00       	jmp    f0100f1b <check_page_free_list+0x2bd>
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d84:	39 ca                	cmp    %ecx,%edx
f0100d86:	73 24                	jae    f0100dac <check_page_free_list+0x14e>
f0100d88:	c7 44 24 0c da 58 10 	movl   $0xf01058da,0xc(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100d97:	f0 
f0100d98:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0100d9f:	00 
f0100da0:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100da7:	e8 0a f3 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100dac:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100daf:	72 24                	jb     f0100dd5 <check_page_free_list+0x177>
f0100db1:	c7 44 24 0c fb 58 10 	movl   $0xf01058fb,0xc(%esp)
f0100db8:	f0 
f0100db9:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100dc0:	f0 
f0100dc1:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0100dc8:	00 
f0100dc9:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100dd0:	e8 e1 f2 ff ff       	call   f01000b6 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100dd5:	89 d0                	mov    %edx,%eax
f0100dd7:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100dda:	a8 07                	test   $0x7,%al
f0100ddc:	74 24                	je     f0100e02 <check_page_free_list+0x1a4>
f0100dde:	c7 44 24 0c 94 5b 10 	movl   $0xf0105b94,0xc(%esp)
f0100de5:	f0 
f0100de6:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100ded:	f0 
f0100dee:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0100df5:	00 
f0100df6:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100dfd:	e8 b4 f2 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e02:	c1 f8 03             	sar    $0x3,%eax
f0100e05:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e08:	85 c0                	test   %eax,%eax
f0100e0a:	75 24                	jne    f0100e30 <check_page_free_list+0x1d2>
f0100e0c:	c7 44 24 0c 0f 59 10 	movl   $0xf010590f,0xc(%esp)
f0100e13:	f0 
f0100e14:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100e1b:	f0 
f0100e1c:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0100e23:	00 
f0100e24:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100e2b:	e8 86 f2 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e30:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e35:	75 24                	jne    f0100e5b <check_page_free_list+0x1fd>
f0100e37:	c7 44 24 0c 20 59 10 	movl   $0xf0105920,0xc(%esp)
f0100e3e:	f0 
f0100e3f:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100e46:	f0 
f0100e47:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0100e4e:	00 
f0100e4f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100e56:	e8 5b f2 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e5b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e60:	75 24                	jne    f0100e86 <check_page_free_list+0x228>
f0100e62:	c7 44 24 0c c4 5b 10 	movl   $0xf0105bc4,0xc(%esp)
f0100e69:	f0 
f0100e6a:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100e71:	f0 
f0100e72:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
f0100e79:	00 
f0100e7a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100e81:	e8 30 f2 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e86:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e8b:	75 24                	jne    f0100eb1 <check_page_free_list+0x253>
f0100e8d:	c7 44 24 0c 39 59 10 	movl   $0xf0105939,0xc(%esp)
f0100e94:	f0 
f0100e95:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100e9c:	f0 
f0100e9d:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0100ea4:	00 
f0100ea5:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100eac:	e8 05 f2 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100eb1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100eb6:	76 58                	jbe    f0100f10 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb8:	89 c3                	mov    %eax,%ebx
f0100eba:	c1 eb 0c             	shr    $0xc,%ebx
f0100ebd:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100ec0:	77 20                	ja     f0100ee2 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec6:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0100ecd:	f0 
f0100ece:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ed5:	00 
f0100ed6:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f0100edd:	e8 d4 f1 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100ee2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee7:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100eea:	76 2a                	jbe    f0100f16 <check_page_free_list+0x2b8>
f0100eec:	c7 44 24 0c e8 5b 10 	movl   $0xf0105be8,0xc(%esp)
f0100ef3:	f0 
f0100ef4:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100efb:	f0 
f0100efc:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0100f03:	00 
f0100f04:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100f0b:	e8 a6 f1 ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f10:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100f14:	eb 03                	jmp    f0100f19 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100f16:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f19:	8b 12                	mov    (%edx),%edx
f0100f1b:	85 d2                	test   %edx,%edx
f0100f1d:	0f 85 61 fe ff ff    	jne    f0100d84 <check_page_free_list+0x126>
f0100f23:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f26:	85 db                	test   %ebx,%ebx
f0100f28:	7f 24                	jg     f0100f4e <check_page_free_list+0x2f0>
f0100f2a:	c7 44 24 0c 53 59 10 	movl   $0xf0105953,0xc(%esp)
f0100f31:	f0 
f0100f32:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100f39:	f0 
f0100f3a:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0100f41:	00 
f0100f42:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100f49:	e8 68 f1 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100f4e:	85 ff                	test   %edi,%edi
f0100f50:	7f 4d                	jg     f0100f9f <check_page_free_list+0x341>
f0100f52:	c7 44 24 0c 65 59 10 	movl   $0xf0105965,0xc(%esp)
f0100f59:	f0 
f0100f5a:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0100f61:	f0 
f0100f62:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0100f69:	00 
f0100f6a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0100f71:	e8 40 f1 ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f76:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0100f7b:	85 c0                	test   %eax,%eax
f0100f7d:	0f 85 0d fd ff ff    	jne    f0100c90 <check_page_free_list+0x32>
f0100f83:	e9 ec fc ff ff       	jmp    f0100c74 <check_page_free_list+0x16>
f0100f88:	83 3d e0 e1 17 f0 00 	cmpl   $0x0,0xf017e1e0
f0100f8f:	0f 84 df fc ff ff    	je     f0100c74 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f95:	be 00 04 00 00       	mov    $0x400,%esi
f0100f9a:	e9 3f fd ff ff       	jmp    f0100cde <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100f9f:	83 c4 4c             	add    $0x4c,%esp
f0100fa2:	5b                   	pop    %ebx
f0100fa3:	5e                   	pop    %esi
f0100fa4:	5f                   	pop    %edi
f0100fa5:	5d                   	pop    %ebp
f0100fa6:	c3                   	ret    

f0100fa7 <page_init>:
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void page_init(void)
{
f0100fa7:	55                   	push   %ebp
f0100fa8:	89 e5                	mov    %esp,%ebp
f0100faa:	56                   	push   %esi
f0100fab:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	//num_alloc：在extmem区域已经被占用的页的个数
	size_t i;
	for (i = 0; i < npages; i++)
f0100fac:	be 00 00 00 00       	mov    $0x0,%esi
f0100fb1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fb6:	e9 c5 00 00 00       	jmp    f0101080 <page_init+0xd9>
	{
		if (i == 0)
f0100fbb:	85 db                	test   %ebx,%ebx
f0100fbd:	75 16                	jne    f0100fd5 <page_init+0x2e>
		{
			pages[i].pp_ref = 1;
f0100fbf:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
f0100fc4:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100fca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fd0:	e9 a5 00 00 00       	jmp    f010107a <page_init+0xd3>
		}
		else if (i >= 1 && i < npages_basemem)
f0100fd5:	3b 1d e4 e1 17 f0    	cmp    0xf017e1e4,%ebx
f0100fdb:	73 25                	jae    f0101002 <page_init+0x5b>
		{
			pages[i].pp_ref = 0;
f0100fdd:	89 f0                	mov    %esi,%eax
f0100fdf:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f0100fe5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100feb:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
f0100ff1:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100ff3:	89 f0                	mov    %esi,%eax
f0100ff5:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f0100ffb:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
f0101000:	eb 78                	jmp    f010107a <page_init+0xd3>
f0101002:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
		}
		else if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE)
f0101008:	83 f8 5f             	cmp    $0x5f,%eax
f010100b:	77 16                	ja     f0101023 <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f010100d:	89 f0                	mov    %esi,%eax
f010100f:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f0101015:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f010101b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101021:	eb 57                	jmp    f010107a <page_init+0xd3>
		}

		else if (i >= EXTPHYSMEM / PGSIZE &&
f0101023:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101029:	76 2c                	jbe    f0101057 <page_init+0xb0>
				 i < ((int)(boot_alloc(0)) - KERNBASE) / PGSIZE)
f010102b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101030:	e8 0b fb ff ff       	call   f0100b40 <boot_alloc>
f0101035:	05 00 00 00 10       	add    $0x10000000,%eax
f010103a:	c1 e8 0c             	shr    $0xc,%eax
		{
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}

		else if (i >= EXTPHYSMEM / PGSIZE &&
f010103d:	39 c3                	cmp    %eax,%ebx
f010103f:	73 16                	jae    f0101057 <page_init+0xb0>
				 i < ((int)(boot_alloc(0)) - KERNBASE) / PGSIZE)
		{
			pages[i].pp_ref = 1;
f0101041:	89 f0                	mov    %esi,%eax
f0101043:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f0101049:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f010104f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101055:	eb 23                	jmp    f010107a <page_init+0xd3>
		}
		else
		{
			pages[i].pp_ref = 0;
f0101057:	89 f0                	mov    %esi,%eax
f0101059:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f010105f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0101065:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
f010106b:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f010106d:	89 f0                	mov    %esi,%eax
f010106f:	03 05 ac ee 17 f0    	add    0xf017eeac,%eax
f0101075:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	//num_alloc：在extmem区域已经被占用的页的个数
	size_t i;
	for (i = 0; i < npages; i++)
f010107a:	83 c3 01             	add    $0x1,%ebx
f010107d:	83 c6 08             	add    $0x8,%esi
f0101080:	3b 1d a4 ee 17 f0    	cmp    0xf017eea4,%ebx
f0101086:	0f 82 2f ff ff ff    	jb     f0100fbb <page_init+0x14>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f010108c:	5b                   	pop    %ebx
f010108d:	5e                   	pop    %esi
f010108e:	5d                   	pop    %ebp
f010108f:	c3                   	ret    

f0101090 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101090:	55                   	push   %ebp
f0101091:	89 e5                	mov    %esp,%ebp
f0101093:	53                   	push   %ebx
f0101094:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == NULL)
f0101097:	8b 1d e0 e1 17 f0    	mov    0xf017e1e0,%ebx
f010109d:	85 db                	test   %ebx,%ebx
f010109f:	74 6f                	je     f0101110 <page_alloc+0x80>
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page->pp_link;
f01010a1:	8b 03                	mov    (%ebx),%eax
f01010a3:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
	page->pp_link = 0;
f01010a8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), 0, PGSIZE);
	return page;
f01010ae:	89 d8                	mov    %ebx,%eax
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page->pp_link;
	page->pp_link = 0;
	if (alloc_flags & ALLOC_ZERO)
f01010b0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010b4:	74 5f                	je     f0101115 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010b6:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01010bc:	c1 f8 03             	sar    $0x3,%eax
f01010bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010c2:	89 c2                	mov    %eax,%edx
f01010c4:	c1 ea 0c             	shr    $0xc,%edx
f01010c7:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f01010cd:	72 20                	jb     f01010ef <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010d3:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f01010da:	f0 
f01010db:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010e2:	00 
f01010e3:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01010ea:	e8 c7 ef ff ff       	call   f01000b6 <_panic>
		memset(page2kva(page), 0, PGSIZE);
f01010ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01010f6:	00 
f01010f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01010fe:	00 
	return (void *)(pa + KERNBASE);
f01010ff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101104:	89 04 24             	mov    %eax,(%esp)
f0101107:	e8 bb 3c 00 00       	call   f0104dc7 <memset>
	return page;
f010110c:	89 d8                	mov    %ebx,%eax
f010110e:	eb 05                	jmp    f0101115 <page_alloc+0x85>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == NULL)
		return NULL;
f0101110:	b8 00 00 00 00       	mov    $0x0,%eax
	page_free_list = page->pp_link;
	page->pp_link = 0;
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), 0, PGSIZE);
	return page;
}
f0101115:	83 c4 14             	add    $0x14,%esp
f0101118:	5b                   	pop    %ebx
f0101119:	5d                   	pop    %ebp
f010111a:	c3                   	ret    

f010111b <page_free>:
//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void page_free(struct PageInfo *pp)
{
f010111b:	55                   	push   %ebp
f010111c:	89 e5                	mov    %esp,%ebp
f010111e:	83 ec 18             	sub    $0x18,%esp
f0101121:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref != 0 || pp->pp_link != NULL)
f0101124:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101129:	75 05                	jne    f0101130 <page_free+0x15>
f010112b:	83 38 00             	cmpl   $0x0,(%eax)
f010112e:	74 1c                	je     f010114c <page_free+0x31>

	{

		panic("can‘tfree this page! page in use or in the free list");
f0101130:	c7 44 24 08 2c 5c 10 	movl   $0xf0105c2c,0x8(%esp)
f0101137:	f0 
f0101138:	c7 44 24 04 63 01 00 	movl   $0x163,0x4(%esp)
f010113f:	00 
f0101140:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101147:	e8 6a ef ff ff       	call   f01000b6 <_panic>
	}

	pp->pp_link = page_free_list;
f010114c:	8b 15 e0 e1 17 f0    	mov    0xf017e1e0,%edx
f0101152:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;
f0101154:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0
}
f0101159:	c9                   	leave  
f010115a:	c3                   	ret    

f010115b <page_decref>:
//
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void page_decref(struct PageInfo *pp)
{
f010115b:	55                   	push   %ebp
f010115c:	89 e5                	mov    %esp,%ebp
f010115e:	83 ec 18             	sub    $0x18,%esp
f0101161:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101164:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101168:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010116b:	66 89 50 04          	mov    %dx,0x4(%eax)
f010116f:	66 85 d2             	test   %dx,%dx
f0101172:	75 08                	jne    f010117c <page_decref+0x21>
		page_free(pp);
f0101174:	89 04 24             	mov    %eax,(%esp)
f0101177:	e8 9f ff ff ff       	call   f010111b <page_free>
}
f010117c:	c9                   	leave  
f010117d:	c3                   	ret    

f010117e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010117e:	55                   	push   %ebp
f010117f:	89 e5                	mov    %esp,%ebp
f0101181:	56                   	push   %esi
f0101182:	53                   	push   %ebx
f0101183:	83 ec 10             	sub    $0x10,%esp
f0101186:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	int pdeIndex = (unsigned int)va >> 22;
f0101189:	89 f3                	mov    %esi,%ebx
f010118b:	c1 eb 16             	shr    $0x16,%ebx
	if (pgdir[pdeIndex] == 0 && create == 0)
f010118e:	c1 e3 02             	shl    $0x2,%ebx
f0101191:	03 5d 08             	add    0x8(%ebp),%ebx
f0101194:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101197:	75 2c                	jne    f01011c5 <pgdir_walk+0x47>
f0101199:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010119d:	74 6c                	je     f010120b <pgdir_walk+0x8d>
		return NULL;
	if (pgdir[pdeIndex] == 0)
	{
		struct PageInfo *page = page_alloc(1);
f010119f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01011a6:	e8 e5 fe ff ff       	call   f0101090 <page_alloc>
		if (page == NULL)
f01011ab:	85 c0                	test   %eax,%eax
f01011ad:	74 63                	je     f0101212 <pgdir_walk+0x94>
			return NULL;
		page->pp_ref++;
f01011af:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011b4:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01011ba:	c1 f8 03             	sar    $0x3,%eax
f01011bd:	c1 e0 0c             	shl    $0xc,%eax
		pte_t pgAddress = page2pa(page);
		pgAddress |= PTE_U;
		pgAddress |= PTE_P;
		pgAddress |= PTE_W;
f01011c0:	83 c8 07             	or     $0x7,%eax
f01011c3:	89 03                	mov    %eax,(%ebx)
		pgdir[pdeIndex] = pgAddress;
	}
	pte_t pgAdd = pgdir[pdeIndex];
f01011c5:	8b 03                	mov    (%ebx),%eax
	pgAdd = pgAdd >> 12 << 12;
	int pteIndex = (pte_t)va >> 12 & 0x3ff;
f01011c7:	c1 ee 0a             	shr    $0xa,%esi
	pte_t *pte = (pte_t *)pgAdd + pteIndex;
f01011ca:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
		pgAddress |= PTE_P;
		pgAddress |= PTE_W;
		pgdir[pdeIndex] = pgAddress;
	}
	pte_t pgAdd = pgdir[pdeIndex];
	pgAdd = pgAdd >> 12 << 12;
f01011d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	int pteIndex = (pte_t)va >> 12 & 0x3ff;
	pte_t *pte = (pte_t *)pgAdd + pteIndex;
f01011d5:	01 f0                	add    %esi,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011d7:	89 c2                	mov    %eax,%edx
f01011d9:	c1 ea 0c             	shr    $0xc,%edx
f01011dc:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f01011e2:	72 20                	jb     f0101204 <pgdir_walk+0x86>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011e8:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
f01011f7:	00 
f01011f8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01011ff:	e8 b2 ee ff ff       	call   f01000b6 <_panic>
	return KADDR((pte_t)pte);
f0101204:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101209:	eb 0c                	jmp    f0101217 <pgdir_walk+0x99>
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	int pdeIndex = (unsigned int)va >> 22;
	if (pgdir[pdeIndex] == 0 && create == 0)
		return NULL;
f010120b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101210:	eb 05                	jmp    f0101217 <pgdir_walk+0x99>
	if (pgdir[pdeIndex] == 0)
	{
		struct PageInfo *page = page_alloc(1);
		if (page == NULL)
			return NULL;
f0101212:	b8 00 00 00 00       	mov    $0x0,%eax
	pte_t pgAdd = pgdir[pdeIndex];
	pgAdd = pgAdd >> 12 << 12;
	int pteIndex = (pte_t)va >> 12 & 0x3ff;
	pte_t *pte = (pte_t *)pgAdd + pteIndex;
	return KADDR((pte_t)pte);
}
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	5b                   	pop    %ebx
f010121b:	5e                   	pop    %esi
f010121c:	5d                   	pop    %ebp
f010121d:	c3                   	ret    

f010121e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010121e:	55                   	push   %ebp
f010121f:	89 e5                	mov    %esp,%ebp
f0101221:	57                   	push   %edi
f0101222:	56                   	push   %esi
f0101223:	53                   	push   %ebx
f0101224:	83 ec 2c             	sub    $0x2c,%esp
f0101227:	89 c7                	mov    %eax,%edi
f0101229:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t pgs = size / PGSIZE;
f010122c:	89 cb                	mov    %ecx,%ebx
f010122e:	c1 eb 0c             	shr    $0xc,%ebx
	if (size % PGSIZE != 0)
f0101231:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
	{
		pgs++;
f0101237:	83 f9 01             	cmp    $0x1,%ecx
f010123a:	83 db ff             	sbb    $0xffffffff,%ebx
f010123d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}
	//计算总共有多少页
	int i = 0;
	for (i = 0; i < pgs; i++)
f0101240:	89 c3                	mov    %eax,%ebx
f0101242:	be 00 00 00 00       	mov    $0x0,%esi
f0101247:	29 c2                	sub    %eax,%edx
f0101249:	89 55 e0             	mov    %edx,-0x20(%ebp)
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1); //获取va对应的PTE的地址
		if (pte == NULL)
		{
			panic("boot_map_region(): out of memory\n");
		}
		*pte = pa | PTE_P | perm; //修改va对应的PTE的值
f010124c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010124f:	83 c8 01             	or     $0x1,%eax
f0101252:	89 45 dc             	mov    %eax,-0x24(%ebp)
	{
		pgs++;
	}
	//计算总共有多少页
	int i = 0;
	for (i = 0; i < pgs; i++)
f0101255:	eb 49                	jmp    f01012a0 <boot_map_region+0x82>
	{
		pte_t *pte = pgdir_walk(pgdir, (void *)va, 1); //获取va对应的PTE的地址
f0101257:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010125e:	00 
f010125f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101262:	01 d8                	add    %ebx,%eax
f0101264:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101268:	89 3c 24             	mov    %edi,(%esp)
f010126b:	e8 0e ff ff ff       	call   f010117e <pgdir_walk>
		if (pte == NULL)
f0101270:	85 c0                	test   %eax,%eax
f0101272:	75 1c                	jne    f0101290 <boot_map_region+0x72>
		{
			panic("boot_map_region(): out of memory\n");
f0101274:	c7 44 24 08 64 5c 10 	movl   $0xf0105c64,0x8(%esp)
f010127b:	f0 
f010127c:	c7 44 24 04 c0 01 00 	movl   $0x1c0,0x4(%esp)
f0101283:	00 
f0101284:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010128b:	e8 26 ee ff ff       	call   f01000b6 <_panic>
		}
		*pte = pa | PTE_P | perm; //修改va对应的PTE的值
f0101290:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101293:	09 da                	or     %ebx,%edx
f0101295:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;			  //更新pa和va，进行下一轮循环
f0101297:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	{
		pgs++;
	}
	//计算总共有多少页
	int i = 0;
	for (i = 0; i < pgs; i++)
f010129d:	83 c6 01             	add    $0x1,%esi
f01012a0:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01012a3:	75 b2                	jne    f0101257 <boot_map_region+0x39>
	// 	*pte= pa |perm|PTE_P;
	// 	size -= PGSIZE;
	// 	pa  += PGSIZE;
	// 	va  += PGSIZE;
	// }
}
f01012a5:	83 c4 2c             	add    $0x2c,%esp
f01012a8:	5b                   	pop    %ebx
f01012a9:	5e                   	pop    %esi
f01012aa:	5f                   	pop    %edi
f01012ab:	5d                   	pop    %ebp
f01012ac:	c3                   	ret    

f01012ad <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01012ad:	55                   	push   %ebp
f01012ae:	89 e5                	mov    %esp,%ebp
f01012b0:	53                   	push   %ebx
f01012b1:	83 ec 14             	sub    $0x14,%esp
f01012b4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;

	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0); //根据虚拟地址va找到页表项
f01012b7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01012be:	00 
f01012bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c9:	89 04 24             	mov    %eax,(%esp)
f01012cc:	e8 ad fe ff ff       	call   f010117e <pgdir_walk>
f01012d1:	89 c2                	mov    %eax,%edx

	if (entry == NULL)
f01012d3:	85 c0                	test   %eax,%eax
f01012d5:	74 3e                	je     f0101315 <page_lookup+0x68>

		return NULL;

	if (!(*entry & PTE_P))
f01012d7:	8b 00                	mov    (%eax),%eax
f01012d9:	a8 01                	test   $0x1,%al
f01012db:	74 3f                	je     f010131c <page_lookup+0x6f>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012dd:	c1 e8 0c             	shr    $0xc,%eax
f01012e0:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f01012e6:	72 1c                	jb     f0101304 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01012e8:	c7 44 24 08 88 5c 10 	movl   $0xf0105c88,0x8(%esp)
f01012ef:	f0 
f01012f0:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01012f7:	00 
f01012f8:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01012ff:	e8 b2 ed ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0101304:	8b 0d ac ee 17 f0    	mov    0xf017eeac,%ecx
f010130a:	8d 04 c1             	lea    (%ecx,%eax,8),%eax

		return NULL;

	ret = pa2page(PTE_ADDR(*entry));

	if (pte_store != NULL)
f010130d:	85 db                	test   %ebx,%ebx
f010130f:	74 10                	je     f0101321 <page_lookup+0x74>

	{

		*pte_store = entry; //将页表项pte的地址存储到pte_store中
f0101311:	89 13                	mov    %edx,(%ebx)
f0101313:	eb 0c                	jmp    f0101321 <page_lookup+0x74>

	entry = pgdir_walk(pgdir, va, 0); //根据虚拟地址va找到页表项

	if (entry == NULL)

		return NULL;
f0101315:	b8 00 00 00 00       	mov    $0x0,%eax
f010131a:	eb 05                	jmp    f0101321 <page_lookup+0x74>

	if (!(*entry & PTE_P))

		return NULL;
f010131c:	b8 00 00 00 00       	mov    $0x0,%eax

		*pte_store = entry; //将页表项pte的地址存储到pte_store中
	}

	return ret;
}
f0101321:	83 c4 14             	add    $0x14,%esp
f0101324:	5b                   	pop    %ebx
f0101325:	5d                   	pop    %ebp
f0101326:	c3                   	ret    

f0101327 <page_remove>:
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void page_remove(pde_t *pgdir, void *va)
{
f0101327:	55                   	push   %ebp
f0101328:	89 e5                	mov    %esp,%ebp
f010132a:	53                   	push   %ebx
f010132b:	83 ec 24             	sub    $0x24,%esp
f010132e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;

	pte_t **pte_store = &pte;

	struct PageInfo *pp = page_lookup(pgdir, va, pte_store); //找到va对应的物理页
f0101331:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101334:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101338:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010133c:	8b 45 08             	mov    0x8(%ebp),%eax
f010133f:	89 04 24             	mov    %eax,(%esp)
f0101342:	e8 66 ff ff ff       	call   f01012ad <page_lookup>

	if (!pp) //如果不存在，就直接返回
f0101347:	85 c0                	test   %eax,%eax
f0101349:	74 14                	je     f010135f <page_remove+0x38>

		return;

	page_decref(pp); //将pp页的引用计数-1
f010134b:	89 04 24             	mov    %eax,(%esp)
f010134e:	e8 08 fe ff ff       	call   f010115b <page_decref>

	**pte_store = 0; //将页表项置0
f0101353:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101356:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010135c:	0f 01 3b             	invlpg (%ebx)

	tlb_invalidate(pgdir, va); //将TLB置为无效
}
f010135f:	83 c4 24             	add    $0x24,%esp
f0101362:	5b                   	pop    %ebx
f0101363:	5d                   	pop    %ebp
f0101364:	c3                   	ret    

f0101365 <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101365:	55                   	push   %ebp
f0101366:	89 e5                	mov    %esp,%ebp
f0101368:	57                   	push   %edi
f0101369:	56                   	push   %esi
f010136a:	53                   	push   %ebx
f010136b:	83 ec 1c             	sub    $0x1c,%esp
f010136e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101371:	8b 7d 0c             	mov    0xc(%ebp),%edi
	// Fill this function in
	pte_t *entry = NULL;

	entry = pgdir_walk(pgdir, va, 1); //通过pgdir_walk函数求出va对应的页表项
f0101374:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010137b:	00 
f010137c:	8b 45 10             	mov    0x10(%ebp),%eax
f010137f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101383:	89 1c 24             	mov    %ebx,(%esp)
f0101386:	e8 f3 fd ff ff       	call   f010117e <pgdir_walk>
f010138b:	89 c6                	mov    %eax,%esi

	if (entry == NULL)
f010138d:	85 c0                	test   %eax,%eax
f010138f:	74 48                	je     f01013d9 <page_insert+0x74>
		return -E_NO_MEM;

	pp->pp_ref++; //修改引用计数值
f0101391:	66 83 47 04 01       	addw   $0x1,0x4(%edi)

	if ((*entry) & PTE_P) //如果这个虚拟地址已有物理页与之映射
f0101396:	f6 00 01             	testb  $0x1,(%eax)
f0101399:	74 15                	je     f01013b0 <page_insert+0x4b>
f010139b:	8b 45 10             	mov    0x10(%ebp),%eax
f010139e:	0f 01 38             	invlpg (%eax)

	{

		tlb_invalidate(pgdir, va); //TLB无效

		page_remove(pgdir, va); //删除这个映射
f01013a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01013a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013a8:	89 1c 24             	mov    %ebx,(%esp)
f01013ab:	e8 77 ff ff ff       	call   f0101327 <page_remove>
	}

	*entry = (page2pa(pp) | perm | PTE_P);
f01013b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01013b3:	83 c8 01             	or     $0x1,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013b6:	2b 3d ac ee 17 f0    	sub    0xf017eeac,%edi
f01013bc:	c1 ff 03             	sar    $0x3,%edi
f01013bf:	c1 e7 0c             	shl    $0xc,%edi
f01013c2:	09 c7                	or     %eax,%edi
f01013c4:	89 3e                	mov    %edi,(%esi)

	pgdir[PDX(va)] |= perm; //把va和pp的映射关系查到页目录中
f01013c6:	8b 45 10             	mov    0x10(%ebp),%eax
f01013c9:	c1 e8 16             	shr    $0x16,%eax
f01013cc:	8b 55 14             	mov    0x14(%ebp),%edx
f01013cf:	09 14 83             	or     %edx,(%ebx,%eax,4)

	return 0;
f01013d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d7:	eb 05                	jmp    f01013de <page_insert+0x79>
	pte_t *entry = NULL;

	entry = pgdir_walk(pgdir, va, 1); //通过pgdir_walk函数求出va对应的页表项

	if (entry == NULL)
		return -E_NO_MEM;
f01013d9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*entry = (page2pa(pp) | perm | PTE_P);

	pgdir[PDX(va)] |= perm; //把va和pp的映射关系查到页目录中

	return 0;
}
f01013de:	83 c4 1c             	add    $0x1c,%esp
f01013e1:	5b                   	pop    %ebx
f01013e2:	5e                   	pop    %esi
f01013e3:	5f                   	pop    %edi
f01013e4:	5d                   	pop    %ebp
f01013e5:	c3                   	ret    

f01013e6 <mem_init>:
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void mem_init(void)
{
f01013e6:	55                   	push   %ebp
f01013e7:	89 e5                	mov    %esp,%ebp
f01013e9:	57                   	push   %edi
f01013ea:	56                   	push   %esi
f01013eb:	53                   	push   %ebx
f01013ec:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013ef:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01013f6:	e8 58 25 00 00       	call   f0103953 <mc146818_read>
f01013fb:	89 c3                	mov    %eax,%ebx
f01013fd:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101404:	e8 4a 25 00 00       	call   f0103953 <mc146818_read>
f0101409:	c1 e0 08             	shl    $0x8,%eax
f010140c:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010140e:	89 d8                	mov    %ebx,%eax
f0101410:	c1 e0 0a             	shl    $0xa,%eax
f0101413:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101419:	85 c0                	test   %eax,%eax
f010141b:	0f 48 c2             	cmovs  %edx,%eax
f010141e:	c1 f8 0c             	sar    $0xc,%eax
f0101421:	a3 e4 e1 17 f0       	mov    %eax,0xf017e1e4
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101426:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010142d:	e8 21 25 00 00       	call   f0103953 <mc146818_read>
f0101432:	89 c3                	mov    %eax,%ebx
f0101434:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010143b:	e8 13 25 00 00       	call   f0103953 <mc146818_read>
f0101440:	c1 e0 08             	shl    $0x8,%eax
f0101443:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101445:	89 d8                	mov    %ebx,%eax
f0101447:	c1 e0 0a             	shl    $0xa,%eax
f010144a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101450:	85 c0                	test   %eax,%eax
f0101452:	0f 48 c2             	cmovs  %edx,%eax
f0101455:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101458:	85 c0                	test   %eax,%eax
f010145a:	74 0e                	je     f010146a <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010145c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101462:	89 15 a4 ee 17 f0    	mov    %edx,0xf017eea4
f0101468:	eb 0c                	jmp    f0101476 <mem_init+0x90>
	else
		npages = npages_basemem;
f010146a:	8b 15 e4 e1 17 f0    	mov    0xf017e1e4,%edx
f0101470:	89 15 a4 ee 17 f0    	mov    %edx,0xf017eea4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
			npages * PGSIZE / 1024,
			npages_basemem * PGSIZE / 1024,
			npages_extmem * PGSIZE / 1024);
f0101476:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101479:	c1 e8 0a             	shr    $0xa,%eax
f010147c:	89 44 24 0c          	mov    %eax,0xc(%esp)
			npages * PGSIZE / 1024,
			npages_basemem * PGSIZE / 1024,
f0101480:	a1 e4 e1 17 f0       	mov    0xf017e1e4,%eax
f0101485:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101488:	c1 e8 0a             	shr    $0xa,%eax
f010148b:	89 44 24 08          	mov    %eax,0x8(%esp)
			npages * PGSIZE / 1024,
f010148f:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0101494:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101497:	c1 e8 0a             	shr    $0xa,%eax
f010149a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010149e:	c7 04 24 a8 5c 10 f0 	movl   $0xf0105ca8,(%esp)
f01014a5:	e8 19 25 00 00       	call   f01039c3 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE); //kern_pgdir会分配给它PGSIZE（一个页）大小的内存
f01014aa:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014af:	e8 8c f6 ff ff       	call   f0100b40 <boot_alloc>
f01014b4:	a3 a8 ee 17 f0       	mov    %eax,0xf017eea8
	memset(kern_pgdir, 0, PGSIZE);
f01014b9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01014c0:	00 
f01014c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014c8:	00 
f01014c9:	89 04 24             	mov    %eax,(%esp)
f01014cc:	e8 f6 38 00 00       	call   f0104dc7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014d1:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014d6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014db:	77 20                	ja     f01014fd <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014e1:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f01014e8:	f0 
f01014e9:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
f01014f0:	00 
f01014f1:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01014f8:	e8 b9 eb ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014fd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101503:	83 ca 05             	or     $0x5,%edx
f0101506:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f010150c:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0101511:	c1 e0 03             	shl    $0x3,%eax
f0101514:	e8 27 f6 ff ff       	call   f0100b40 <boot_alloc>
f0101519:	a3 ac ee 17 f0       	mov    %eax,0xf017eeac
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f010151e:	8b 3d a4 ee 17 f0    	mov    0xf017eea4,%edi
f0101524:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010152b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010152f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101536:	00 
f0101537:	89 04 24             	mov    %eax,(%esp)
f010153a:	e8 88 38 00 00       	call   f0104dc7 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(sizeof(struct Env) * NENV);
f010153f:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101544:	e8 f7 f5 ff ff       	call   f0100b40 <boot_alloc>
f0101549:	a3 ec e1 17 f0       	mov    %eax,0xf017e1ec
	memset(envs, 0, sizeof(struct Env) * NENV);
f010154e:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101555:	00 
f0101556:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010155d:	00 
f010155e:	89 04 24             	mov    %eax,(%esp)
f0101561:	e8 61 38 00 00       	call   f0104dc7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101566:	e8 3c fa ff ff       	call   f0100fa7 <page_init>

	check_page_free_list(1);
f010156b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101570:	e8 e9 f6 ff ff       	call   f0100c5e <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101575:	83 3d ac ee 17 f0 00 	cmpl   $0x0,0xf017eeac
f010157c:	75 1c                	jne    f010159a <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010157e:	c7 44 24 08 76 59 10 	movl   $0xf0105976,0x8(%esp)
f0101585:	f0 
f0101586:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f010158d:	00 
f010158e:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101595:	e8 1c eb ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010159a:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f010159f:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015a4:	eb 05                	jmp    f01015ab <mem_init+0x1c5>
		++nfree;
f01015a6:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015a9:	8b 00                	mov    (%eax),%eax
f01015ab:	85 c0                	test   %eax,%eax
f01015ad:	75 f7                	jne    f01015a6 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b6:	e8 d5 fa ff ff       	call   f0101090 <page_alloc>
f01015bb:	89 c7                	mov    %eax,%edi
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	75 24                	jne    f01015e5 <mem_init+0x1ff>
f01015c1:	c7 44 24 0c 91 59 10 	movl   $0xf0105991,0xc(%esp)
f01015c8:	f0 
f01015c9:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01015d0:	f0 
f01015d1:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f01015d8:	00 
f01015d9:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01015e0:	e8 d1 ea ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01015e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ec:	e8 9f fa ff ff       	call   f0101090 <page_alloc>
f01015f1:	89 c6                	mov    %eax,%esi
f01015f3:	85 c0                	test   %eax,%eax
f01015f5:	75 24                	jne    f010161b <mem_init+0x235>
f01015f7:	c7 44 24 0c a7 59 10 	movl   $0xf01059a7,0xc(%esp)
f01015fe:	f0 
f01015ff:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101606:	f0 
f0101607:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f010160e:	00 
f010160f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101616:	e8 9b ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010161b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101622:	e8 69 fa ff ff       	call   f0101090 <page_alloc>
f0101627:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010162a:	85 c0                	test   %eax,%eax
f010162c:	75 24                	jne    f0101652 <mem_init+0x26c>
f010162e:	c7 44 24 0c bd 59 10 	movl   $0xf01059bd,0xc(%esp)
f0101635:	f0 
f0101636:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010163d:	f0 
f010163e:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101645:	00 
f0101646:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010164d:	e8 64 ea ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101652:	39 f7                	cmp    %esi,%edi
f0101654:	75 24                	jne    f010167a <mem_init+0x294>
f0101656:	c7 44 24 0c d3 59 10 	movl   $0xf01059d3,0xc(%esp)
f010165d:	f0 
f010165e:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101665:	f0 
f0101666:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f010166d:	00 
f010166e:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101675:	e8 3c ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010167a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010167d:	39 c6                	cmp    %eax,%esi
f010167f:	74 04                	je     f0101685 <mem_init+0x29f>
f0101681:	39 c7                	cmp    %eax,%edi
f0101683:	75 24                	jne    f01016a9 <mem_init+0x2c3>
f0101685:	c7 44 24 0c 08 5d 10 	movl   $0xf0105d08,0xc(%esp)
f010168c:	f0 
f010168d:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101694:	f0 
f0101695:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f010169c:	00 
f010169d:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01016a4:	e8 0d ea ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016a9:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
	assert(page2pa(pp0) < npages * PGSIZE);
f01016af:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f01016b4:	c1 e0 0c             	shl    $0xc,%eax
f01016b7:	89 f9                	mov    %edi,%ecx
f01016b9:	29 d1                	sub    %edx,%ecx
f01016bb:	c1 f9 03             	sar    $0x3,%ecx
f01016be:	c1 e1 0c             	shl    $0xc,%ecx
f01016c1:	39 c1                	cmp    %eax,%ecx
f01016c3:	72 24                	jb     f01016e9 <mem_init+0x303>
f01016c5:	c7 44 24 0c 28 5d 10 	movl   $0xf0105d28,0xc(%esp)
f01016cc:	f0 
f01016cd:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01016d4:	f0 
f01016d5:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f01016dc:	00 
f01016dd:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01016e4:	e8 cd e9 ff ff       	call   f01000b6 <_panic>
f01016e9:	89 f1                	mov    %esi,%ecx
f01016eb:	29 d1                	sub    %edx,%ecx
f01016ed:	c1 f9 03             	sar    $0x3,%ecx
f01016f0:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages * PGSIZE);
f01016f3:	39 c8                	cmp    %ecx,%eax
f01016f5:	77 24                	ja     f010171b <mem_init+0x335>
f01016f7:	c7 44 24 0c 48 5d 10 	movl   $0xf0105d48,0xc(%esp)
f01016fe:	f0 
f01016ff:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101706:	f0 
f0101707:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f010170e:	00 
f010170f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101716:	e8 9b e9 ff ff       	call   f01000b6 <_panic>
f010171b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010171e:	29 d1                	sub    %edx,%ecx
f0101720:	89 ca                	mov    %ecx,%edx
f0101722:	c1 fa 03             	sar    $0x3,%edx
f0101725:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages * PGSIZE);
f0101728:	39 d0                	cmp    %edx,%eax
f010172a:	77 24                	ja     f0101750 <mem_init+0x36a>
f010172c:	c7 44 24 0c 68 5d 10 	movl   $0xf0105d68,0xc(%esp)
f0101733:	f0 
f0101734:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010173b:	f0 
f010173c:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101743:	00 
f0101744:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010174b:	e8 66 e9 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101750:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101755:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101758:	c7 05 e0 e1 17 f0 00 	movl   $0x0,0xf017e1e0
f010175f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101762:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101769:	e8 22 f9 ff ff       	call   f0101090 <page_alloc>
f010176e:	85 c0                	test   %eax,%eax
f0101770:	74 24                	je     f0101796 <mem_init+0x3b0>
f0101772:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f0101779:	f0 
f010177a:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101781:	f0 
f0101782:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101789:	00 
f010178a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101791:	e8 20 e9 ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101796:	89 3c 24             	mov    %edi,(%esp)
f0101799:	e8 7d f9 ff ff       	call   f010111b <page_free>
	page_free(pp1);
f010179e:	89 34 24             	mov    %esi,(%esp)
f01017a1:	e8 75 f9 ff ff       	call   f010111b <page_free>
	page_free(pp2);
f01017a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017a9:	89 04 24             	mov    %eax,(%esp)
f01017ac:	e8 6a f9 ff ff       	call   f010111b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017b1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017b8:	e8 d3 f8 ff ff       	call   f0101090 <page_alloc>
f01017bd:	89 c6                	mov    %eax,%esi
f01017bf:	85 c0                	test   %eax,%eax
f01017c1:	75 24                	jne    f01017e7 <mem_init+0x401>
f01017c3:	c7 44 24 0c 91 59 10 	movl   $0xf0105991,0xc(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01017d2:	f0 
f01017d3:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01017da:	00 
f01017db:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01017e2:	e8 cf e8 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01017e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ee:	e8 9d f8 ff ff       	call   f0101090 <page_alloc>
f01017f3:	89 c7                	mov    %eax,%edi
f01017f5:	85 c0                	test   %eax,%eax
f01017f7:	75 24                	jne    f010181d <mem_init+0x437>
f01017f9:	c7 44 24 0c a7 59 10 	movl   $0xf01059a7,0xc(%esp)
f0101800:	f0 
f0101801:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101808:	f0 
f0101809:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101810:	00 
f0101811:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101818:	e8 99 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f010181d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101824:	e8 67 f8 ff ff       	call   f0101090 <page_alloc>
f0101829:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010182c:	85 c0                	test   %eax,%eax
f010182e:	75 24                	jne    f0101854 <mem_init+0x46e>
f0101830:	c7 44 24 0c bd 59 10 	movl   $0xf01059bd,0xc(%esp)
f0101837:	f0 
f0101838:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010183f:	f0 
f0101840:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101847:	00 
f0101848:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010184f:	e8 62 e8 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101854:	39 fe                	cmp    %edi,%esi
f0101856:	75 24                	jne    f010187c <mem_init+0x496>
f0101858:	c7 44 24 0c d3 59 10 	movl   $0xf01059d3,0xc(%esp)
f010185f:	f0 
f0101860:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101867:	f0 
f0101868:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f010186f:	00 
f0101870:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101877:	e8 3a e8 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010187c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010187f:	39 c7                	cmp    %eax,%edi
f0101881:	74 04                	je     f0101887 <mem_init+0x4a1>
f0101883:	39 c6                	cmp    %eax,%esi
f0101885:	75 24                	jne    f01018ab <mem_init+0x4c5>
f0101887:	c7 44 24 0c 08 5d 10 	movl   $0xf0105d08,0xc(%esp)
f010188e:	f0 
f010188f:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101896:	f0 
f0101897:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f010189e:	00 
f010189f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01018a6:	e8 0b e8 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f01018ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b2:	e8 d9 f7 ff ff       	call   f0101090 <page_alloc>
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	74 24                	je     f01018df <mem_init+0x4f9>
f01018bb:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f01018c2:	f0 
f01018c3:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01018ca:	f0 
f01018cb:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f01018d2:	00 
f01018d3:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01018da:	e8 d7 e7 ff ff       	call   f01000b6 <_panic>
f01018df:	89 f0                	mov    %esi,%eax
f01018e1:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01018e7:	c1 f8 03             	sar    $0x3,%eax
f01018ea:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018ed:	89 c2                	mov    %eax,%edx
f01018ef:	c1 ea 0c             	shr    $0xc,%edx
f01018f2:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f01018f8:	72 20                	jb     f010191a <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018fe:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0101905:	f0 
f0101906:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010190d:	00 
f010190e:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f0101915:	e8 9c e7 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010191a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101921:	00 
f0101922:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101929:	00 
	return (void *)(pa + KERNBASE);
f010192a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010192f:	89 04 24             	mov    %eax,(%esp)
f0101932:	e8 90 34 00 00       	call   f0104dc7 <memset>
	page_free(pp0);
f0101937:	89 34 24             	mov    %esi,(%esp)
f010193a:	e8 dc f7 ff ff       	call   f010111b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010193f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101946:	e8 45 f7 ff ff       	call   f0101090 <page_alloc>
f010194b:	85 c0                	test   %eax,%eax
f010194d:	75 24                	jne    f0101973 <mem_init+0x58d>
f010194f:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f0101956:	f0 
f0101957:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010195e:	f0 
f010195f:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101966:	00 
f0101967:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010196e:	e8 43 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101973:	39 c6                	cmp    %eax,%esi
f0101975:	74 24                	je     f010199b <mem_init+0x5b5>
f0101977:	c7 44 24 0c 12 5a 10 	movl   $0xf0105a12,0xc(%esp)
f010197e:	f0 
f010197f:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101986:	f0 
f0101987:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f010198e:	00 
f010198f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101996:	e8 1b e7 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010199b:	89 f0                	mov    %esi,%eax
f010199d:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01019a3:	c1 f8 03             	sar    $0x3,%eax
f01019a6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019a9:	89 c2                	mov    %eax,%edx
f01019ab:	c1 ea 0c             	shr    $0xc,%edx
f01019ae:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f01019b4:	72 20                	jb     f01019d6 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019b6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019ba:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f01019c1:	f0 
f01019c2:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01019c9:	00 
f01019ca:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01019d1:	e8 e0 e6 ff ff       	call   f01000b6 <_panic>
f01019d6:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01019dc:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01019e2:	80 38 00             	cmpb   $0x0,(%eax)
f01019e5:	74 24                	je     f0101a0b <mem_init+0x625>
f01019e7:	c7 44 24 0c 22 5a 10 	movl   $0xf0105a22,0xc(%esp)
f01019ee:	f0 
f01019ef:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01019f6:	f0 
f01019f7:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f01019fe:	00 
f01019ff:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101a06:	e8 ab e6 ff ff       	call   f01000b6 <_panic>
f0101a0b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101a0e:	39 d0                	cmp    %edx,%eax
f0101a10:	75 d0                	jne    f01019e2 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101a12:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a15:	a3 e0 e1 17 f0       	mov    %eax,0xf017e1e0

	// free the pages we took
	page_free(pp0);
f0101a1a:	89 34 24             	mov    %esi,(%esp)
f0101a1d:	e8 f9 f6 ff ff       	call   f010111b <page_free>
	page_free(pp1);
f0101a22:	89 3c 24             	mov    %edi,(%esp)
f0101a25:	e8 f1 f6 ff ff       	call   f010111b <page_free>
	page_free(pp2);
f0101a2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2d:	89 04 24             	mov    %eax,(%esp)
f0101a30:	e8 e6 f6 ff ff       	call   f010111b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a35:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101a3a:	eb 05                	jmp    f0101a41 <mem_init+0x65b>
		--nfree;
f0101a3c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a3f:	8b 00                	mov    (%eax),%eax
f0101a41:	85 c0                	test   %eax,%eax
f0101a43:	75 f7                	jne    f0101a3c <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101a45:	85 db                	test   %ebx,%ebx
f0101a47:	74 24                	je     f0101a6d <mem_init+0x687>
f0101a49:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f0101a50:	f0 
f0101a51:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101a58:	f0 
f0101a59:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101a60:	00 
f0101a61:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101a68:	e8 49 e6 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101a6d:	c7 04 24 88 5d 10 f0 	movl   $0xf0105d88,(%esp)
f0101a74:	e8 4a 1f 00 00       	call   f01039c3 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a80:	e8 0b f6 ff ff       	call   f0101090 <page_alloc>
f0101a85:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a88:	85 c0                	test   %eax,%eax
f0101a8a:	75 24                	jne    f0101ab0 <mem_init+0x6ca>
f0101a8c:	c7 44 24 0c 91 59 10 	movl   $0xf0105991,0xc(%esp)
f0101a93:	f0 
f0101a94:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101a9b:	f0 
f0101a9c:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0101aa3:	00 
f0101aa4:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101aab:	e8 06 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101ab0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ab7:	e8 d4 f5 ff ff       	call   f0101090 <page_alloc>
f0101abc:	89 c3                	mov    %eax,%ebx
f0101abe:	85 c0                	test   %eax,%eax
f0101ac0:	75 24                	jne    f0101ae6 <mem_init+0x700>
f0101ac2:	c7 44 24 0c a7 59 10 	movl   $0xf01059a7,0xc(%esp)
f0101ac9:	f0 
f0101aca:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0101ad9:	00 
f0101ada:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101ae1:	e8 d0 e5 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101ae6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aed:	e8 9e f5 ff ff       	call   f0101090 <page_alloc>
f0101af2:	89 c6                	mov    %eax,%esi
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	75 24                	jne    f0101b1c <mem_init+0x736>
f0101af8:	c7 44 24 0c bd 59 10 	movl   $0xf01059bd,0xc(%esp)
f0101aff:	f0 
f0101b00:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101b07:	f0 
f0101b08:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0101b0f:	00 
f0101b10:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101b17:	e8 9a e5 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b1c:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101b1f:	75 24                	jne    f0101b45 <mem_init+0x75f>
f0101b21:	c7 44 24 0c d3 59 10 	movl   $0xf01059d3,0xc(%esp)
f0101b28:	f0 
f0101b29:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101b30:	f0 
f0101b31:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0101b38:	00 
f0101b39:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101b40:	e8 71 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b45:	39 c3                	cmp    %eax,%ebx
f0101b47:	74 05                	je     f0101b4e <mem_init+0x768>
f0101b49:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b4c:	75 24                	jne    f0101b72 <mem_init+0x78c>
f0101b4e:	c7 44 24 0c 08 5d 10 	movl   $0xf0105d08,0xc(%esp)
f0101b55:	f0 
f0101b56:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101b5d:	f0 
f0101b5e:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101b65:	00 
f0101b66:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101b6d:	e8 44 e5 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b72:	a1 e0 e1 17 f0       	mov    0xf017e1e0,%eax
f0101b77:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b7a:	c7 05 e0 e1 17 f0 00 	movl   $0x0,0xf017e1e0
f0101b81:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b84:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b8b:	e8 00 f5 ff ff       	call   f0101090 <page_alloc>
f0101b90:	85 c0                	test   %eax,%eax
f0101b92:	74 24                	je     f0101bb8 <mem_init+0x7d2>
f0101b94:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f0101b9b:	f0 
f0101b9c:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0101bab:	00 
f0101bac:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101bb3:	e8 fe e4 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f0101bb8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101bbb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bbf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101bc6:	00 
f0101bc7:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101bcc:	89 04 24             	mov    %eax,(%esp)
f0101bcf:	e8 d9 f6 ff ff       	call   f01012ad <page_lookup>
f0101bd4:	85 c0                	test   %eax,%eax
f0101bd6:	74 24                	je     f0101bfc <mem_init+0x816>
f0101bd8:	c7 44 24 0c a8 5d 10 	movl   $0xf0105da8,0xc(%esp)
f0101bdf:	f0 
f0101be0:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101be7:	f0 
f0101be8:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0101bef:	00 
f0101bf0:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101bf7:	e8 ba e4 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101bfc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c03:	00 
f0101c04:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c0b:	00 
f0101c0c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c10:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101c15:	89 04 24             	mov    %eax,(%esp)
f0101c18:	e8 48 f7 ff ff       	call   f0101365 <page_insert>
f0101c1d:	85 c0                	test   %eax,%eax
f0101c1f:	78 24                	js     f0101c45 <mem_init+0x85f>
f0101c21:	c7 44 24 0c dc 5d 10 	movl   $0xf0105ddc,0xc(%esp)
f0101c28:	f0 
f0101c29:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101c30:	f0 
f0101c31:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0101c38:	00 
f0101c39:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101c40:	e8 71 e4 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c48:	89 04 24             	mov    %eax,(%esp)
f0101c4b:	e8 cb f4 ff ff       	call   f010111b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c50:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c57:	00 
f0101c58:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c5f:	00 
f0101c60:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c64:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101c69:	89 04 24             	mov    %eax,(%esp)
f0101c6c:	e8 f4 f6 ff ff       	call   f0101365 <page_insert>
f0101c71:	85 c0                	test   %eax,%eax
f0101c73:	74 24                	je     f0101c99 <mem_init+0x8b3>
f0101c75:	c7 44 24 0c 0c 5e 10 	movl   $0xf0105e0c,0xc(%esp)
f0101c7c:	f0 
f0101c7d:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0101c8c:	00 
f0101c8d:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101c94:	e8 1d e4 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c99:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c9f:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
f0101ca4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ca7:	8b 17                	mov    (%edi),%edx
f0101ca9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101caf:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cb2:	29 c1                	sub    %eax,%ecx
f0101cb4:	89 c8                	mov    %ecx,%eax
f0101cb6:	c1 f8 03             	sar    $0x3,%eax
f0101cb9:	c1 e0 0c             	shl    $0xc,%eax
f0101cbc:	39 c2                	cmp    %eax,%edx
f0101cbe:	74 24                	je     f0101ce4 <mem_init+0x8fe>
f0101cc0:	c7 44 24 0c 3c 5e 10 	movl   $0xf0105e3c,0xc(%esp)
f0101cc7:	f0 
f0101cc8:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101ccf:	f0 
f0101cd0:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0101cd7:	00 
f0101cd8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101cdf:	e8 d2 e3 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ce4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ce9:	89 f8                	mov    %edi,%eax
f0101ceb:	e8 ff ee ff ff       	call   f0100bef <check_va2pa>
f0101cf0:	89 da                	mov    %ebx,%edx
f0101cf2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101cf5:	c1 fa 03             	sar    $0x3,%edx
f0101cf8:	c1 e2 0c             	shl    $0xc,%edx
f0101cfb:	39 d0                	cmp    %edx,%eax
f0101cfd:	74 24                	je     f0101d23 <mem_init+0x93d>
f0101cff:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f0101d06:	f0 
f0101d07:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101d0e:	f0 
f0101d0f:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0101d16:	00 
f0101d17:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101d1e:	e8 93 e3 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101d23:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d28:	74 24                	je     f0101d4e <mem_init+0x968>
f0101d2a:	c7 44 24 0c 37 5a 10 	movl   $0xf0105a37,0xc(%esp)
f0101d31:	f0 
f0101d32:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101d39:	f0 
f0101d3a:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0101d41:	00 
f0101d42:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101d49:	e8 68 e3 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101d4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d51:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d56:	74 24                	je     f0101d7c <mem_init+0x996>
f0101d58:	c7 44 24 0c 48 5a 10 	movl   $0xf0105a48,0xc(%esp)
f0101d5f:	f0 
f0101d60:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101d67:	f0 
f0101d68:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0101d6f:	00 
f0101d70:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101d77:	e8 3a e3 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101d7c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d83:	00 
f0101d84:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d8b:	00 
f0101d8c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d90:	89 3c 24             	mov    %edi,(%esp)
f0101d93:	e8 cd f5 ff ff       	call   f0101365 <page_insert>
f0101d98:	85 c0                	test   %eax,%eax
f0101d9a:	74 24                	je     f0101dc0 <mem_init+0x9da>
f0101d9c:	c7 44 24 0c 94 5e 10 	movl   $0xf0105e94,0xc(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101dab:	f0 
f0101dac:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0101db3:	00 
f0101db4:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101dbb:	e8 f6 e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dc0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc5:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101dca:	e8 20 ee ff ff       	call   f0100bef <check_va2pa>
f0101dcf:	89 f2                	mov    %esi,%edx
f0101dd1:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0101dd7:	c1 fa 03             	sar    $0x3,%edx
f0101dda:	c1 e2 0c             	shl    $0xc,%edx
f0101ddd:	39 d0                	cmp    %edx,%eax
f0101ddf:	74 24                	je     f0101e05 <mem_init+0xa1f>
f0101de1:	c7 44 24 0c d0 5e 10 	movl   $0xf0105ed0,0xc(%esp)
f0101de8:	f0 
f0101de9:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101df0:	f0 
f0101df1:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0101df8:	00 
f0101df9:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101e00:	e8 b1 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e05:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e0a:	74 24                	je     f0101e30 <mem_init+0xa4a>
f0101e0c:	c7 44 24 0c 59 5a 10 	movl   $0xf0105a59,0xc(%esp)
f0101e13:	f0 
f0101e14:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101e1b:	f0 
f0101e1c:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0101e23:	00 
f0101e24:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101e2b:	e8 86 e2 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e37:	e8 54 f2 ff ff       	call   f0101090 <page_alloc>
f0101e3c:	85 c0                	test   %eax,%eax
f0101e3e:	74 24                	je     f0101e64 <mem_init+0xa7e>
f0101e40:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f0101e47:	f0 
f0101e48:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101e4f:	f0 
f0101e50:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0101e57:	00 
f0101e58:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101e5f:	e8 52 e2 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101e64:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e6b:	00 
f0101e6c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e73:	00 
f0101e74:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e78:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101e7d:	89 04 24             	mov    %eax,(%esp)
f0101e80:	e8 e0 f4 ff ff       	call   f0101365 <page_insert>
f0101e85:	85 c0                	test   %eax,%eax
f0101e87:	74 24                	je     f0101ead <mem_init+0xac7>
f0101e89:	c7 44 24 0c 94 5e 10 	movl   $0xf0105e94,0xc(%esp)
f0101e90:	f0 
f0101e91:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101e98:	f0 
f0101e99:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0101ea0:	00 
f0101ea1:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101ea8:	e8 09 e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ead:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eb2:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101eb7:	e8 33 ed ff ff       	call   f0100bef <check_va2pa>
f0101ebc:	89 f2                	mov    %esi,%edx
f0101ebe:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0101ec4:	c1 fa 03             	sar    $0x3,%edx
f0101ec7:	c1 e2 0c             	shl    $0xc,%edx
f0101eca:	39 d0                	cmp    %edx,%eax
f0101ecc:	74 24                	je     f0101ef2 <mem_init+0xb0c>
f0101ece:	c7 44 24 0c d0 5e 10 	movl   $0xf0105ed0,0xc(%esp)
f0101ed5:	f0 
f0101ed6:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101edd:	f0 
f0101ede:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0101ee5:	00 
f0101ee6:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101eed:	e8 c4 e1 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ef2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ef7:	74 24                	je     f0101f1d <mem_init+0xb37>
f0101ef9:	c7 44 24 0c 59 5a 10 	movl   $0xf0105a59,0xc(%esp)
f0101f00:	f0 
f0101f01:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101f08:	f0 
f0101f09:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101f10:	00 
f0101f11:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101f18:	e8 99 e1 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f1d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f24:	e8 67 f1 ff ff       	call   f0101090 <page_alloc>
f0101f29:	85 c0                	test   %eax,%eax
f0101f2b:	74 24                	je     f0101f51 <mem_init+0xb6b>
f0101f2d:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101f3c:	f0 
f0101f3d:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0101f44:	00 
f0101f45:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101f4c:	e8 65 e1 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f51:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
f0101f57:	8b 02                	mov    (%edx),%eax
f0101f59:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f5e:	89 c1                	mov    %eax,%ecx
f0101f60:	c1 e9 0c             	shr    $0xc,%ecx
f0101f63:	3b 0d a4 ee 17 f0    	cmp    0xf017eea4,%ecx
f0101f69:	72 20                	jb     f0101f8b <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f6f:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f0101f76:	f0 
f0101f77:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f0101f7e:	00 
f0101f7f:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101f86:	e8 2b e1 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101f8b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f90:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101f93:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f9a:	00 
f0101f9b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fa2:	00 
f0101fa3:	89 14 24             	mov    %edx,(%esp)
f0101fa6:	e8 d3 f1 ff ff       	call   f010117e <pgdir_walk>
f0101fab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101fae:	8d 57 04             	lea    0x4(%edi),%edx
f0101fb1:	39 d0                	cmp    %edx,%eax
f0101fb3:	74 24                	je     f0101fd9 <mem_init+0xbf3>
f0101fb5:	c7 44 24 0c 00 5f 10 	movl   $0xf0105f00,0xc(%esp)
f0101fbc:	f0 
f0101fbd:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0101fc4:	f0 
f0101fc5:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0101fcc:	00 
f0101fcd:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0101fd4:	e8 dd e0 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101fd9:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101fe0:	00 
f0101fe1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fe8:	00 
f0101fe9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101fed:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0101ff2:	89 04 24             	mov    %eax,(%esp)
f0101ff5:	e8 6b f3 ff ff       	call   f0101365 <page_insert>
f0101ffa:	85 c0                	test   %eax,%eax
f0101ffc:	74 24                	je     f0102022 <mem_init+0xc3c>
f0101ffe:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f0102005:	f0 
f0102006:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010200d:	f0 
f010200e:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0102015:	00 
f0102016:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010201d:	e8 94 e0 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102022:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f0102028:	ba 00 10 00 00       	mov    $0x1000,%edx
f010202d:	89 f8                	mov    %edi,%eax
f010202f:	e8 bb eb ff ff       	call   f0100bef <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102034:	89 f2                	mov    %esi,%edx
f0102036:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f010203c:	c1 fa 03             	sar    $0x3,%edx
f010203f:	c1 e2 0c             	shl    $0xc,%edx
f0102042:	39 d0                	cmp    %edx,%eax
f0102044:	74 24                	je     f010206a <mem_init+0xc84>
f0102046:	c7 44 24 0c d0 5e 10 	movl   $0xf0105ed0,0xc(%esp)
f010204d:	f0 
f010204e:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102055:	f0 
f0102056:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f010205d:	00 
f010205e:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102065:	e8 4c e0 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f010206a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010206f:	74 24                	je     f0102095 <mem_init+0xcaf>
f0102071:	c7 44 24 0c 59 5a 10 	movl   $0xf0105a59,0xc(%esp)
f0102078:	f0 
f0102079:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102080:	f0 
f0102081:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0102088:	00 
f0102089:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102090:	e8 21 e0 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0102095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010209c:	00 
f010209d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020a4:	00 
f01020a5:	89 3c 24             	mov    %edi,(%esp)
f01020a8:	e8 d1 f0 ff ff       	call   f010117e <pgdir_walk>
f01020ad:	f6 00 04             	testb  $0x4,(%eax)
f01020b0:	75 24                	jne    f01020d6 <mem_init+0xcf0>
f01020b2:	c7 44 24 0c 84 5f 10 	movl   $0xf0105f84,0xc(%esp)
f01020b9:	f0 
f01020ba:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01020c1:	f0 
f01020c2:	c7 44 24 04 bc 03 00 	movl   $0x3bc,0x4(%esp)
f01020c9:	00 
f01020ca:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01020d1:	e8 e0 df ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01020d6:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01020db:	f6 00 04             	testb  $0x4,(%eax)
f01020de:	75 24                	jne    f0102104 <mem_init+0xd1e>
f01020e0:	c7 44 24 0c 6a 5a 10 	movl   $0xf0105a6a,0xc(%esp)
f01020e7:	f0 
f01020e8:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f01020f7:	00 
f01020f8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01020ff:	e8 b2 df ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0102104:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010210b:	00 
f010210c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102113:	00 
f0102114:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102118:	89 04 24             	mov    %eax,(%esp)
f010211b:	e8 45 f2 ff ff       	call   f0101365 <page_insert>
f0102120:	85 c0                	test   %eax,%eax
f0102122:	74 24                	je     f0102148 <mem_init+0xd62>
f0102124:	c7 44 24 0c 94 5e 10 	movl   $0xf0105e94,0xc(%esp)
f010212b:	f0 
f010212c:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102133:	f0 
f0102134:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f010213b:	00 
f010213c:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102143:	e8 6e df ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0102148:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010214f:	00 
f0102150:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102157:	00 
f0102158:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010215d:	89 04 24             	mov    %eax,(%esp)
f0102160:	e8 19 f0 ff ff       	call   f010117e <pgdir_walk>
f0102165:	f6 00 02             	testb  $0x2,(%eax)
f0102168:	75 24                	jne    f010218e <mem_init+0xda8>
f010216a:	c7 44 24 0c b8 5f 10 	movl   $0xf0105fb8,0xc(%esp)
f0102171:	f0 
f0102172:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102179:	f0 
f010217a:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0102181:	00 
f0102182:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102189:	e8 28 df ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f010218e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102195:	00 
f0102196:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010219d:	00 
f010219e:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01021a3:	89 04 24             	mov    %eax,(%esp)
f01021a6:	e8 d3 ef ff ff       	call   f010117e <pgdir_walk>
f01021ab:	f6 00 04             	testb  $0x4,(%eax)
f01021ae:	74 24                	je     f01021d4 <mem_init+0xdee>
f01021b0:	c7 44 24 0c ec 5f 10 	movl   $0xf0105fec,0xc(%esp)
f01021b7:	f0 
f01021b8:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01021bf:	f0 
f01021c0:	c7 44 24 04 c2 03 00 	movl   $0x3c2,0x4(%esp)
f01021c7:	00 
f01021c8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01021cf:	e8 e2 de ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f01021d4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021db:	00 
f01021dc:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021e3:	00 
f01021e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01021eb:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01021f0:	89 04 24             	mov    %eax,(%esp)
f01021f3:	e8 6d f1 ff ff       	call   f0101365 <page_insert>
f01021f8:	85 c0                	test   %eax,%eax
f01021fa:	78 24                	js     f0102220 <mem_init+0xe3a>
f01021fc:	c7 44 24 0c 24 60 10 	movl   $0xf0106024,0xc(%esp)
f0102203:	f0 
f0102204:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010220b:	f0 
f010220c:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f0102213:	00 
f0102214:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010221b:	e8 96 de ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0102220:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102227:	00 
f0102228:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010222f:	00 
f0102230:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102234:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102239:	89 04 24             	mov    %eax,(%esp)
f010223c:	e8 24 f1 ff ff       	call   f0101365 <page_insert>
f0102241:	85 c0                	test   %eax,%eax
f0102243:	74 24                	je     f0102269 <mem_init+0xe83>
f0102245:	c7 44 24 0c 5c 60 10 	movl   $0xf010605c,0xc(%esp)
f010224c:	f0 
f010224d:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102254:	f0 
f0102255:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f010225c:	00 
f010225d:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102264:	e8 4d de ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0102269:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102270:	00 
f0102271:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102278:	00 
f0102279:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010227e:	89 04 24             	mov    %eax,(%esp)
f0102281:	e8 f8 ee ff ff       	call   f010117e <pgdir_walk>
f0102286:	f6 00 04             	testb  $0x4,(%eax)
f0102289:	74 24                	je     f01022af <mem_init+0xec9>
f010228b:	c7 44 24 0c ec 5f 10 	movl   $0xf0105fec,0xc(%esp)
f0102292:	f0 
f0102293:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010229a:	f0 
f010229b:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f01022a2:	00 
f01022a3:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01022aa:	e8 07 de ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022af:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f01022b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01022ba:	89 f8                	mov    %edi,%eax
f01022bc:	e8 2e e9 ff ff       	call   f0100bef <check_va2pa>
f01022c1:	89 c1                	mov    %eax,%ecx
f01022c3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022c6:	89 d8                	mov    %ebx,%eax
f01022c8:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01022ce:	c1 f8 03             	sar    $0x3,%eax
f01022d1:	c1 e0 0c             	shl    $0xc,%eax
f01022d4:	39 c1                	cmp    %eax,%ecx
f01022d6:	74 24                	je     f01022fc <mem_init+0xf16>
f01022d8:	c7 44 24 0c 98 60 10 	movl   $0xf0106098,0xc(%esp)
f01022df:	f0 
f01022e0:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01022e7:	f0 
f01022e8:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f01022ef:	00 
f01022f0:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01022f7:	e8 ba dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022fc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102301:	89 f8                	mov    %edi,%eax
f0102303:	e8 e7 e8 ff ff       	call   f0100bef <check_va2pa>
f0102308:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010230b:	74 24                	je     f0102331 <mem_init+0xf4b>
f010230d:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0102314:	f0 
f0102315:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010231c:	f0 
f010231d:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102324:	00 
f0102325:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010232c:	e8 85 dd ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102331:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102336:	74 24                	je     f010235c <mem_init+0xf76>
f0102338:	c7 44 24 0c 80 5a 10 	movl   $0xf0105a80,0xc(%esp)
f010233f:	f0 
f0102340:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102347:	f0 
f0102348:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f010234f:	00 
f0102350:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102357:	e8 5a dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010235c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102361:	74 24                	je     f0102387 <mem_init+0xfa1>
f0102363:	c7 44 24 0c 91 5a 10 	movl   $0xf0105a91,0xc(%esp)
f010236a:	f0 
f010236b:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102372:	f0 
f0102373:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f010237a:	00 
f010237b:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102382:	e8 2f dd ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102387:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010238e:	e8 fd ec ff ff       	call   f0101090 <page_alloc>
f0102393:	85 c0                	test   %eax,%eax
f0102395:	74 04                	je     f010239b <mem_init+0xfb5>
f0102397:	39 c6                	cmp    %eax,%esi
f0102399:	74 24                	je     f01023bf <mem_init+0xfd9>
f010239b:	c7 44 24 0c f4 60 10 	movl   $0xf01060f4,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01023ba:	e8 f7 dc ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023c6:	00 
f01023c7:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01023cc:	89 04 24             	mov    %eax,(%esp)
f01023cf:	e8 53 ef ff ff       	call   f0101327 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023d4:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f01023da:	ba 00 00 00 00       	mov    $0x0,%edx
f01023df:	89 f8                	mov    %edi,%eax
f01023e1:	e8 09 e8 ff ff       	call   f0100bef <check_va2pa>
f01023e6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023e9:	74 24                	je     f010240f <mem_init+0x1029>
f01023eb:	c7 44 24 0c 18 61 10 	movl   $0xf0106118,0xc(%esp)
f01023f2:	f0 
f01023f3:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102402:	00 
f0102403:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010240a:	e8 a7 dc ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010240f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102414:	89 f8                	mov    %edi,%eax
f0102416:	e8 d4 e7 ff ff       	call   f0100bef <check_va2pa>
f010241b:	89 da                	mov    %ebx,%edx
f010241d:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0102423:	c1 fa 03             	sar    $0x3,%edx
f0102426:	c1 e2 0c             	shl    $0xc,%edx
f0102429:	39 d0                	cmp    %edx,%eax
f010242b:	74 24                	je     f0102451 <mem_init+0x106b>
f010242d:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0102434:	f0 
f0102435:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010243c:	f0 
f010243d:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f0102444:	00 
f0102445:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010244c:	e8 65 dc ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102451:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102456:	74 24                	je     f010247c <mem_init+0x1096>
f0102458:	c7 44 24 0c 37 5a 10 	movl   $0xf0105a37,0xc(%esp)
f010245f:	f0 
f0102460:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102467:	f0 
f0102468:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f010246f:	00 
f0102470:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102477:	e8 3a dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010247c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102481:	74 24                	je     f01024a7 <mem_init+0x10c1>
f0102483:	c7 44 24 0c 91 5a 10 	movl   $0xf0105a91,0xc(%esp)
f010248a:	f0 
f010248b:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102492:	f0 
f0102493:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f010249a:	00 
f010249b:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01024a2:	e8 0f dc ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f01024a7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01024ae:	00 
f01024af:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024b6:	00 
f01024b7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01024bb:	89 3c 24             	mov    %edi,(%esp)
f01024be:	e8 a2 ee ff ff       	call   f0101365 <page_insert>
f01024c3:	85 c0                	test   %eax,%eax
f01024c5:	74 24                	je     f01024eb <mem_init+0x1105>
f01024c7:	c7 44 24 0c 3c 61 10 	movl   $0xf010613c,0xc(%esp)
f01024ce:	f0 
f01024cf:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01024d6:	f0 
f01024d7:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f01024de:	00 
f01024df:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01024e6:	e8 cb db ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f01024eb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01024f0:	75 24                	jne    f0102516 <mem_init+0x1130>
f01024f2:	c7 44 24 0c a2 5a 10 	movl   $0xf0105aa2,0xc(%esp)
f01024f9:	f0 
f01024fa:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102501:	f0 
f0102502:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102509:	00 
f010250a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102511:	e8 a0 db ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f0102516:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102519:	74 24                	je     f010253f <mem_init+0x1159>
f010251b:	c7 44 24 0c ae 5a 10 	movl   $0xf0105aae,0xc(%esp)
f0102522:	f0 
f0102523:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010252a:	f0 
f010252b:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0102532:	00 
f0102533:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010253a:	e8 77 db ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f010253f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102546:	00 
f0102547:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010254c:	89 04 24             	mov    %eax,(%esp)
f010254f:	e8 d3 ed ff ff       	call   f0101327 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102554:	8b 3d a8 ee 17 f0    	mov    0xf017eea8,%edi
f010255a:	ba 00 00 00 00       	mov    $0x0,%edx
f010255f:	89 f8                	mov    %edi,%eax
f0102561:	e8 89 e6 ff ff       	call   f0100bef <check_va2pa>
f0102566:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102569:	74 24                	je     f010258f <mem_init+0x11a9>
f010256b:	c7 44 24 0c 18 61 10 	movl   $0xf0106118,0xc(%esp)
f0102572:	f0 
f0102573:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010257a:	f0 
f010257b:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0102582:	00 
f0102583:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010258a:	e8 27 db ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010258f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102594:	89 f8                	mov    %edi,%eax
f0102596:	e8 54 e6 ff ff       	call   f0100bef <check_va2pa>
f010259b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010259e:	74 24                	je     f01025c4 <mem_init+0x11de>
f01025a0:	c7 44 24 0c 74 61 10 	movl   $0xf0106174,0xc(%esp)
f01025a7:	f0 
f01025a8:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01025af:	f0 
f01025b0:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f01025b7:	00 
f01025b8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01025bf:	e8 f2 da ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f01025c4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01025c9:	74 24                	je     f01025ef <mem_init+0x1209>
f01025cb:	c7 44 24 0c c3 5a 10 	movl   $0xf0105ac3,0xc(%esp)
f01025d2:	f0 
f01025d3:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01025da:	f0 
f01025db:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f01025e2:	00 
f01025e3:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01025ea:	e8 c7 da ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01025ef:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025f4:	74 24                	je     f010261a <mem_init+0x1234>
f01025f6:	c7 44 24 0c 91 5a 10 	movl   $0xf0105a91,0xc(%esp)
f01025fd:	f0 
f01025fe:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102605:	f0 
f0102606:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f010260d:	00 
f010260e:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102615:	e8 9c da ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010261a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102621:	e8 6a ea ff ff       	call   f0101090 <page_alloc>
f0102626:	85 c0                	test   %eax,%eax
f0102628:	74 04                	je     f010262e <mem_init+0x1248>
f010262a:	39 c3                	cmp    %eax,%ebx
f010262c:	74 24                	je     f0102652 <mem_init+0x126c>
f010262e:	c7 44 24 0c 9c 61 10 	movl   $0xf010619c,0xc(%esp)
f0102635:	f0 
f0102636:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010263d:	f0 
f010263e:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102645:	00 
f0102646:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010264d:	e8 64 da ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102652:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102659:	e8 32 ea ff ff       	call   f0101090 <page_alloc>
f010265e:	85 c0                	test   %eax,%eax
f0102660:	74 24                	je     f0102686 <mem_init+0x12a0>
f0102662:	c7 44 24 0c e5 59 10 	movl   $0xf01059e5,0xc(%esp)
f0102669:	f0 
f010266a:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102671:	f0 
f0102672:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102679:	00 
f010267a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102681:	e8 30 da ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102686:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010268b:	8b 08                	mov    (%eax),%ecx
f010268d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102693:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102696:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f010269c:	c1 fa 03             	sar    $0x3,%edx
f010269f:	c1 e2 0c             	shl    $0xc,%edx
f01026a2:	39 d1                	cmp    %edx,%ecx
f01026a4:	74 24                	je     f01026ca <mem_init+0x12e4>
f01026a6:	c7 44 24 0c 3c 5e 10 	movl   $0xf0105e3c,0xc(%esp)
f01026ad:	f0 
f01026ae:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01026b5:	f0 
f01026b6:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f01026bd:	00 
f01026be:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01026c5:	e8 ec d9 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f01026ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01026d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026d3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01026d8:	74 24                	je     f01026fe <mem_init+0x1318>
f01026da:	c7 44 24 0c 48 5a 10 	movl   $0xf0105a48,0xc(%esp)
f01026e1:	f0 
f01026e2:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01026e9:	f0 
f01026ea:	c7 44 24 04 f1 03 00 	movl   $0x3f1,0x4(%esp)
f01026f1:	00 
f01026f2:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01026f9:	e8 b8 d9 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01026fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102701:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102707:	89 04 24             	mov    %eax,(%esp)
f010270a:	e8 0c ea ff ff       	call   f010111b <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010270f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102716:	00 
f0102717:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010271e:	00 
f010271f:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102724:	89 04 24             	mov    %eax,(%esp)
f0102727:	e8 52 ea ff ff       	call   f010117e <pgdir_walk>
f010272c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010272f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102732:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
f0102738:	8b 7a 04             	mov    0x4(%edx),%edi
f010273b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102741:	8b 0d a4 ee 17 f0    	mov    0xf017eea4,%ecx
f0102747:	89 f8                	mov    %edi,%eax
f0102749:	c1 e8 0c             	shr    $0xc,%eax
f010274c:	39 c8                	cmp    %ecx,%eax
f010274e:	72 20                	jb     f0102770 <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102750:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102754:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f010275b:	f0 
f010275c:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0102763:	00 
f0102764:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010276b:	e8 46 d9 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102770:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102776:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102779:	74 24                	je     f010279f <mem_init+0x13b9>
f010277b:	c7 44 24 0c d4 5a 10 	movl   $0xf0105ad4,0xc(%esp)
f0102782:	f0 
f0102783:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f010278a:	f0 
f010278b:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0102792:	00 
f0102793:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010279a:	e8 17 d9 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010279f:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01027a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027a9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027af:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01027b5:	c1 f8 03             	sar    $0x3,%eax
f01027b8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027bb:	89 c2                	mov    %eax,%edx
f01027bd:	c1 ea 0c             	shr    $0xc,%edx
f01027c0:	39 d1                	cmp    %edx,%ecx
f01027c2:	77 20                	ja     f01027e4 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027c8:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f01027cf:	f0 
f01027d0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01027d7:	00 
f01027d8:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01027df:	e8 d2 d8 ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01027e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01027eb:	00 
f01027ec:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01027f3:	00 
	return (void *)(pa + KERNBASE);
f01027f4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01027f9:	89 04 24             	mov    %eax,(%esp)
f01027fc:	e8 c6 25 00 00       	call   f0104dc7 <memset>
	page_free(pp0);
f0102801:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102804:	89 3c 24             	mov    %edi,(%esp)
f0102807:	e8 0f e9 ff ff       	call   f010111b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010280c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102813:	00 
f0102814:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010281b:	00 
f010281c:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102821:	89 04 24             	mov    %eax,(%esp)
f0102824:	e8 55 e9 ff ff       	call   f010117e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102829:	89 fa                	mov    %edi,%edx
f010282b:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f0102831:	c1 fa 03             	sar    $0x3,%edx
f0102834:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102837:	89 d0                	mov    %edx,%eax
f0102839:	c1 e8 0c             	shr    $0xc,%eax
f010283c:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0102842:	72 20                	jb     f0102864 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102844:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102848:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f010284f:	f0 
f0102850:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102857:	00 
f0102858:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f010285f:	e8 52 d8 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0102864:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f010286a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010286d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102873:	f6 00 01             	testb  $0x1,(%eax)
f0102876:	74 24                	je     f010289c <mem_init+0x14b6>
f0102878:	c7 44 24 0c ec 5a 10 	movl   $0xf0105aec,0xc(%esp)
f010287f:	f0 
f0102880:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102887:	f0 
f0102888:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f010288f:	00 
f0102890:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102897:	e8 1a d8 ff ff       	call   f01000b6 <_panic>
f010289c:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f010289f:	39 d0                	cmp    %edx,%eax
f01028a1:	75 d0                	jne    f0102873 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01028a3:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01028a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028b1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01028b7:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01028ba:	89 3d e0 e1 17 f0    	mov    %edi,0xf017e1e0

	// free the pages we took
	page_free(pp0);
f01028c0:	89 04 24             	mov    %eax,(%esp)
f01028c3:	e8 53 e8 ff ff       	call   f010111b <page_free>
	page_free(pp1);
f01028c8:	89 1c 24             	mov    %ebx,(%esp)
f01028cb:	e8 4b e8 ff ff       	call   f010111b <page_free>
	page_free(pp2);
f01028d0:	89 34 24             	mov    %esi,(%esp)
f01028d3:	e8 43 e8 ff ff       	call   f010111b <page_free>

	cprintf("check_page() succeeded!\n");
f01028d8:	c7 04 24 03 5b 10 f0 	movl   $0xf0105b03,(%esp)
f01028df:	e8 df 10 00 00       	call   f01039c3 <cprintf>
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int perm = PTE_U | PTE_P;
	int i = 0;
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f01028e4:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f01028e9:	8d 34 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%esi
f01028f0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (i = 0; i < n; i = i + PGSIZE)
f01028f6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01028fb:	e9 86 00 00 00       	jmp    f0102986 <mem_init+0x15a0>
f0102900:	8d 8b 00 00 00 ef    	lea    -0x11000000(%ebx),%ecx
		page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *)(UPAGES + i), perm);
f0102906:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010290b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102910:	77 20                	ja     f0102932 <mem_init+0x154c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102912:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102916:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f010291d:	f0 
f010291e:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0102925:	00 
f0102926:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f010292d:	e8 84 d7 ff ff       	call   f01000b6 <_panic>
f0102932:	8d 94 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102939:	c1 ea 0c             	shr    $0xc,%edx
f010293c:	3b 15 a4 ee 17 f0    	cmp    0xf017eea4,%edx
f0102942:	72 1c                	jb     f0102960 <mem_init+0x157a>
		panic("pa2page called with invalid pa");
f0102944:	c7 44 24 08 88 5c 10 	movl   $0xf0105c88,0x8(%esp)
f010294b:	f0 
f010294c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102953:	00 
f0102954:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f010295b:	e8 56 d7 ff ff       	call   f01000b6 <_panic>
f0102960:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0102967:	00 
f0102968:	89 4c 24 08          	mov    %ecx,0x8(%esp)
	return &pages[PGNUM(pa)];
f010296c:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010296f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102973:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102978:	89 04 24             	mov    %eax,(%esp)
f010297b:	e8 e5 e9 ff ff       	call   f0101365 <page_insert>
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int perm = PTE_U | PTE_P;
	int i = 0;
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i = i + PGSIZE)
f0102980:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102986:	89 da                	mov    %ebx,%edx
f0102988:	39 de                	cmp    %ebx,%esi
f010298a:	0f 87 70 ff ff ff    	ja     f0102900 <mem_init+0x151a>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP((sizeof(struct Env) * NENV), PGSIZE), PADDR(envs), (PTE_U | PTE_P));
f0102990:	a1 ec e1 17 f0       	mov    0xf017e1ec,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102995:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010299a:	77 20                	ja     f01029bc <mem_init+0x15d6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010299c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029a0:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f01029a7:	f0 
f01029a8:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f01029af:	00 
f01029b0:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f01029b7:	e8 fa d6 ff ff       	call   f01000b6 <_panic>
f01029bc:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01029c3:	00 
	return (physaddr_t)kva - KERNBASE;
f01029c4:	05 00 00 00 10       	add    $0x10000000,%eax
f01029c9:	89 04 24             	mov    %eax,(%esp)
f01029cc:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01029d1:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01029d6:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f01029db:	e8 3e e8 ff ff       	call   f010121e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029e0:	bb 00 20 11 f0       	mov    $0xf0112000,%ebx
f01029e5:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01029eb:	77 20                	ja     f0102a0d <mem_init+0x1627>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029ed:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01029f1:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f01029f8:	f0 
f01029f9:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0102a00:	00 
f0102a01:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102a08:	e8 a9 d6 ff ff       	call   f01000b6 <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	perm = 0;
	perm = PTE_P | PTE_W;
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm);
f0102a0d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102a14:	00 
f0102a15:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102a1c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102a21:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102a26:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a2b:	e8 ee e7 ff ff       	call   f010121e <boot_map_region>
	int size = ~0;
	size = size - KERNBASE + 1;
	size = ROUNDUP(size, PGSIZE);
	perm = 0;
	perm = PTE_P | PTE_W;
	boot_map_region(kern_pgdir, KERNBASE, size, 0, perm);
f0102a30:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102a37:	00 
f0102a38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a3f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102a44:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102a49:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a4e:	e8 cb e7 ff ff       	call   f010121e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102a53:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102a58:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f0102a5b:	a1 a4 ee 17 f0       	mov    0xf017eea4,%eax
f0102a60:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102a63:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102a6a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102a6f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a72:	8b 3d ac ee 17 f0    	mov    0xf017eeac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a78:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102a7b:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0102a81:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102a84:	be 00 00 00 00       	mov    $0x0,%esi
f0102a89:	eb 6b                	jmp    f0102af6 <mem_init+0x1710>
f0102a8b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102a91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a94:	e8 56 e1 ff ff       	call   f0100bef <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a99:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102aa0:	77 20                	ja     f0102ac2 <mem_init+0x16dc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102aa6:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f0102aad:	f0 
f0102aae:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102ab5:	00 
f0102ab6:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102abd:	e8 f4 d5 ff ff       	call   f01000b6 <_panic>
f0102ac2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102ac5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102ac8:	39 d0                	cmp    %edx,%eax
f0102aca:	74 24                	je     f0102af0 <mem_init+0x170a>
f0102acc:	c7 44 24 0c c0 61 10 	movl   $0xf01061c0,0xc(%esp)
f0102ad3:	f0 
f0102ad4:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102adb:	f0 
f0102adc:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102ae3:	00 
f0102ae4:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102aeb:	e8 c6 d5 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102af0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102af6:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102af9:	77 90                	ja     f0102a8b <mem_init+0x16a5>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102afb:	8b 35 ec e1 17 f0    	mov    0xf017e1ec,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b01:	89 f7                	mov    %esi,%edi
f0102b03:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102b08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b0b:	e8 df e0 ff ff       	call   f0100bef <check_va2pa>
f0102b10:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102b16:	77 20                	ja     f0102b38 <mem_init+0x1752>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b18:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102b1c:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f0102b23:	f0 
f0102b24:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102b2b:	00 
f0102b2c:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102b33:	e8 7e d5 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b38:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102b3d:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102b43:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102b46:	39 c2                	cmp    %eax,%edx
f0102b48:	74 24                	je     f0102b6e <mem_init+0x1788>
f0102b4a:	c7 44 24 0c f4 61 10 	movl   $0xf01061f4,0xc(%esp)
f0102b51:	f0 
f0102b52:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102b59:	f0 
f0102b5a:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102b61:	00 
f0102b62:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102b69:	e8 48 d5 ff ff       	call   f01000b6 <_panic>
f0102b6e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102b74:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102b7a:	0f 85 26 05 00 00    	jne    f01030a6 <mem_init+0x1cc0>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b80:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102b83:	c1 e7 0c             	shl    $0xc,%edi
f0102b86:	be 00 00 00 00       	mov    $0x0,%esi
f0102b8b:	eb 3c                	jmp    f0102bc9 <mem_init+0x17e3>
f0102b8d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b96:	e8 54 e0 ff ff       	call   f0100bef <check_va2pa>
f0102b9b:	39 c6                	cmp    %eax,%esi
f0102b9d:	74 24                	je     f0102bc3 <mem_init+0x17dd>
f0102b9f:	c7 44 24 0c 28 62 10 	movl   $0xf0106228,0xc(%esp)
f0102ba6:	f0 
f0102ba7:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102bae:	f0 
f0102baf:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0102bb6:	00 
f0102bb7:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102bbe:	e8 f3 d4 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bc3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102bc9:	39 fe                	cmp    %edi,%esi
f0102bcb:	72 c0                	jb     f0102b8d <mem_init+0x17a7>
f0102bcd:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102bd2:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102bd8:	89 f2                	mov    %esi,%edx
f0102bda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bdd:	e8 0d e0 ff ff       	call   f0100bef <check_va2pa>
f0102be2:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102be5:	39 d0                	cmp    %edx,%eax
f0102be7:	74 24                	je     f0102c0d <mem_init+0x1827>
f0102be9:	c7 44 24 0c 50 62 10 	movl   $0xf0106250,0xc(%esp)
f0102bf0:	f0 
f0102bf1:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102c00:	00 
f0102c01:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102c08:	e8 a9 d4 ff ff       	call   f01000b6 <_panic>
f0102c0d:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c13:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102c19:	75 bd                	jne    f0102bd8 <mem_init+0x17f2>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c1b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c20:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c23:	89 f8                	mov    %edi,%eax
f0102c25:	e8 c5 df ff ff       	call   f0100bef <check_va2pa>
f0102c2a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c2d:	75 0c                	jne    f0102c3b <mem_init+0x1855>
f0102c2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c34:	89 fa                	mov    %edi,%edx
f0102c36:	e9 f0 00 00 00       	jmp    f0102d2b <mem_init+0x1945>
f0102c3b:	c7 44 24 0c 98 62 10 	movl   $0xf0106298,0xc(%esp)
f0102c42:	f0 
f0102c43:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102c4a:	f0 
f0102c4b:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102c52:	00 
f0102c53:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102c5a:	e8 57 d4 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f0102c5f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102c64:	72 3c                	jb     f0102ca2 <mem_init+0x18bc>
f0102c66:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c6b:	76 07                	jbe    f0102c74 <mem_init+0x188e>
f0102c6d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c72:	75 2e                	jne    f0102ca2 <mem_init+0x18bc>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102c74:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f0102c78:	0f 85 aa 00 00 00    	jne    f0102d28 <mem_init+0x1942>
f0102c7e:	c7 44 24 0c 1c 5b 10 	movl   $0xf0105b1c,0xc(%esp)
f0102c85:	f0 
f0102c86:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102c8d:	f0 
f0102c8e:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102c95:	00 
f0102c96:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102c9d:	e8 14 d4 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE))
f0102ca2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ca7:	76 55                	jbe    f0102cfe <mem_init+0x1918>
			{
				assert(pgdir[i] & PTE_P);
f0102ca9:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102cac:	f6 c1 01             	test   $0x1,%cl
f0102caf:	75 24                	jne    f0102cd5 <mem_init+0x18ef>
f0102cb1:	c7 44 24 0c 1c 5b 10 	movl   $0xf0105b1c,0xc(%esp)
f0102cb8:	f0 
f0102cb9:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102cc0:	f0 
f0102cc1:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0102cc8:	00 
f0102cc9:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102cd0:	e8 e1 d3 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102cd5:	f6 c1 02             	test   $0x2,%cl
f0102cd8:	75 4e                	jne    f0102d28 <mem_init+0x1942>
f0102cda:	c7 44 24 0c 2d 5b 10 	movl   $0xf0105b2d,0xc(%esp)
f0102ce1:	f0 
f0102ce2:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102ce9:	f0 
f0102cea:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0102cf1:	00 
f0102cf2:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102cf9:	e8 b8 d3 ff ff       	call   f01000b6 <_panic>
			}
			else
				assert(pgdir[i] == 0);
f0102cfe:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102d02:	74 24                	je     f0102d28 <mem_init+0x1942>
f0102d04:	c7 44 24 0c 3e 5b 10 	movl   $0xf0105b3e,0xc(%esp)
f0102d0b:	f0 
f0102d0c:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102d13:	f0 
f0102d14:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102d1b:	00 
f0102d1c:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102d23:	e8 8e d3 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102d28:	83 c0 01             	add    $0x1,%eax
f0102d2b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102d30:	0f 85 29 ff ff ff    	jne    f0102c5f <mem_init+0x1879>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d36:	c7 04 24 c8 62 10 f0 	movl   $0xf01062c8,(%esp)
f0102d3d:	e8 81 0c 00 00       	call   f01039c3 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102d42:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102d47:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d4c:	77 20                	ja     f0102d6e <mem_init+0x1988>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d52:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f0102d59:	f0 
f0102d5a:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0102d61:	00 
f0102d62:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102d69:	e8 48 d3 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102d6e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102d73:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102d76:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d7b:	e8 de de ff ff       	call   f0100c5e <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102d80:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_MP;
	cr0 &= ~(CR0_TS | CR0_EM);
f0102d83:	83 e0 f3             	and    $0xfffffff3,%eax
f0102d86:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102d8b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102d8e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d95:	e8 f6 e2 ff ff       	call   f0101090 <page_alloc>
f0102d9a:	89 c3                	mov    %eax,%ebx
f0102d9c:	85 c0                	test   %eax,%eax
f0102d9e:	75 24                	jne    f0102dc4 <mem_init+0x19de>
f0102da0:	c7 44 24 0c 91 59 10 	movl   $0xf0105991,0xc(%esp)
f0102da7:	f0 
f0102da8:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102daf:	f0 
f0102db0:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f0102db7:	00 
f0102db8:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102dbf:	e8 f2 d2 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102dc4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102dcb:	e8 c0 e2 ff ff       	call   f0101090 <page_alloc>
f0102dd0:	89 c7                	mov    %eax,%edi
f0102dd2:	85 c0                	test   %eax,%eax
f0102dd4:	75 24                	jne    f0102dfa <mem_init+0x1a14>
f0102dd6:	c7 44 24 0c a7 59 10 	movl   $0xf01059a7,0xc(%esp)
f0102ddd:	f0 
f0102dde:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102de5:	f0 
f0102de6:	c7 44 24 04 1f 04 00 	movl   $0x41f,0x4(%esp)
f0102ded:	00 
f0102dee:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102df5:	e8 bc d2 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102dfa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e01:	e8 8a e2 ff ff       	call   f0101090 <page_alloc>
f0102e06:	89 c6                	mov    %eax,%esi
f0102e08:	85 c0                	test   %eax,%eax
f0102e0a:	75 24                	jne    f0102e30 <mem_init+0x1a4a>
f0102e0c:	c7 44 24 0c bd 59 10 	movl   $0xf01059bd,0xc(%esp)
f0102e13:	f0 
f0102e14:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102e1b:	f0 
f0102e1c:	c7 44 24 04 20 04 00 	movl   $0x420,0x4(%esp)
f0102e23:	00 
f0102e24:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102e2b:	e8 86 d2 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102e30:	89 1c 24             	mov    %ebx,(%esp)
f0102e33:	e8 e3 e2 ff ff       	call   f010111b <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e38:	89 f8                	mov    %edi,%eax
f0102e3a:	e8 6b dd ff ff       	call   f0100baa <page2kva>
f0102e3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e46:	00 
f0102e47:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102e4e:	00 
f0102e4f:	89 04 24             	mov    %eax,(%esp)
f0102e52:	e8 70 1f 00 00       	call   f0104dc7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102e57:	89 f0                	mov    %esi,%eax
f0102e59:	e8 4c dd ff ff       	call   f0100baa <page2kva>
f0102e5e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e65:	00 
f0102e66:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e6d:	00 
f0102e6e:	89 04 24             	mov    %eax,(%esp)
f0102e71:	e8 51 1f 00 00       	call   f0104dc7 <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f0102e76:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102e7d:	00 
f0102e7e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e85:	00 
f0102e86:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102e8a:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102e8f:	89 04 24             	mov    %eax,(%esp)
f0102e92:	e8 ce e4 ff ff       	call   f0101365 <page_insert>
	assert(pp1->pp_ref == 1);
f0102e97:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102e9c:	74 24                	je     f0102ec2 <mem_init+0x1adc>
f0102e9e:	c7 44 24 0c 37 5a 10 	movl   $0xf0105a37,0xc(%esp)
f0102ea5:	f0 
f0102ea6:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102ead:	f0 
f0102eae:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f0102eb5:	00 
f0102eb6:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102ebd:	e8 f4 d1 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ec2:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ec9:	01 01 01 
f0102ecc:	74 24                	je     f0102ef2 <mem_init+0x1b0c>
f0102ece:	c7 44 24 0c e8 62 10 	movl   $0xf01062e8,0xc(%esp)
f0102ed5:	f0 
f0102ed6:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102edd:	f0 
f0102ede:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0102ee5:	00 
f0102ee6:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102eed:	e8 c4 d1 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102ef2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ef9:	00 
f0102efa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f01:	00 
f0102f02:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f06:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102f0b:	89 04 24             	mov    %eax,(%esp)
f0102f0e:	e8 52 e4 ff ff       	call   f0101365 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f13:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102f1a:	02 02 02 
f0102f1d:	74 24                	je     f0102f43 <mem_init+0x1b5d>
f0102f1f:	c7 44 24 0c 0c 63 10 	movl   $0xf010630c,0xc(%esp)
f0102f26:	f0 
f0102f27:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102f2e:	f0 
f0102f2f:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f0102f36:	00 
f0102f37:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102f3e:	e8 73 d1 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102f43:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f48:	74 24                	je     f0102f6e <mem_init+0x1b88>
f0102f4a:	c7 44 24 0c 59 5a 10 	movl   $0xf0105a59,0xc(%esp)
f0102f51:	f0 
f0102f52:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102f59:	f0 
f0102f5a:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f0102f61:	00 
f0102f62:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102f69:	e8 48 d1 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102f6e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102f73:	74 24                	je     f0102f99 <mem_init+0x1bb3>
f0102f75:	c7 44 24 0c c3 5a 10 	movl   $0xf0105ac3,0xc(%esp)
f0102f7c:	f0 
f0102f7d:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102f84:	f0 
f0102f85:	c7 44 24 04 2a 04 00 	movl   $0x42a,0x4(%esp)
f0102f8c:	00 
f0102f8d:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102f94:	e8 1d d1 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102f99:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102fa0:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102fa3:	89 f0                	mov    %esi,%eax
f0102fa5:	e8 00 dc ff ff       	call   f0100baa <page2kva>
f0102faa:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102fb0:	74 24                	je     f0102fd6 <mem_init+0x1bf0>
f0102fb2:	c7 44 24 0c 30 63 10 	movl   $0xf0106330,0xc(%esp)
f0102fb9:	f0 
f0102fba:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0102fc1:	f0 
f0102fc2:	c7 44 24 04 2c 04 00 	movl   $0x42c,0x4(%esp)
f0102fc9:	00 
f0102fca:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0102fd1:	e8 e0 d0 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f0102fd6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102fdd:	00 
f0102fde:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0102fe3:	89 04 24             	mov    %eax,(%esp)
f0102fe6:	e8 3c e3 ff ff       	call   f0101327 <page_remove>
	assert(pp2->pp_ref == 0);
f0102feb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102ff0:	74 24                	je     f0103016 <mem_init+0x1c30>
f0102ff2:	c7 44 24 0c 91 5a 10 	movl   $0xf0105a91,0xc(%esp)
f0102ff9:	f0 
f0102ffa:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0103001:	f0 
f0103002:	c7 44 24 04 2e 04 00 	movl   $0x42e,0x4(%esp)
f0103009:	00 
f010300a:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0103011:	e8 a0 d0 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103016:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f010301b:	8b 08                	mov    (%eax),%ecx
f010301d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103023:	89 da                	mov    %ebx,%edx
f0103025:	2b 15 ac ee 17 f0    	sub    0xf017eeac,%edx
f010302b:	c1 fa 03             	sar    $0x3,%edx
f010302e:	c1 e2 0c             	shl    $0xc,%edx
f0103031:	39 d1                	cmp    %edx,%ecx
f0103033:	74 24                	je     f0103059 <mem_init+0x1c73>
f0103035:	c7 44 24 0c 3c 5e 10 	movl   $0xf0105e3c,0xc(%esp)
f010303c:	f0 
f010303d:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0103044:	f0 
f0103045:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f010304c:	00 
f010304d:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0103054:	e8 5d d0 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0103059:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010305f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103064:	74 24                	je     f010308a <mem_init+0x1ca4>
f0103066:	c7 44 24 0c 48 5a 10 	movl   $0xf0105a48,0xc(%esp)
f010306d:	f0 
f010306e:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0103075:	f0 
f0103076:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f010307d:	00 
f010307e:	c7 04 24 c0 58 10 f0 	movl   $0xf01058c0,(%esp)
f0103085:	e8 2c d0 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f010308a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103090:	89 1c 24             	mov    %ebx,(%esp)
f0103093:	e8 83 e0 ff ff       	call   f010111b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103098:	c7 04 24 5c 63 10 f0 	movl   $0xf010635c,(%esp)
f010309f:	e8 1f 09 00 00       	call   f01039c3 <cprintf>
f01030a4:	eb 0f                	jmp    f01030b5 <mem_init+0x1ccf>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01030a6:	89 f2                	mov    %esi,%edx
f01030a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030ab:	e8 3f db ff ff       	call   f0100bef <check_va2pa>
f01030b0:	e9 8e fa ff ff       	jmp    f0102b43 <mem_init+0x175d>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01030b5:	83 c4 4c             	add    $0x4c,%esp
f01030b8:	5b                   	pop    %ebx
f01030b9:	5e                   	pop    %esi
f01030ba:	5f                   	pop    %edi
f01030bb:	5d                   	pop    %ebp
f01030bc:	c3                   	ret    

f01030bd <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f01030bd:	55                   	push   %ebp
f01030be:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01030c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c3:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01030c6:	5d                   	pop    %ebp
f01030c7:	c3                   	ret    

f01030c8 <user_mem_check>:
//
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01030c8:	55                   	push   %ebp
f01030c9:	89 e5                	mov    %esp,%ebp
f01030cb:	57                   	push   %edi
f01030cc:	56                   	push   %esi
f01030cd:	53                   	push   %ebx
f01030ce:	83 ec 1c             	sub    $0x1c,%esp
f01030d1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01030d4:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
f01030d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01030da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030e5:	c7 04 24 88 63 10 f0 	movl   $0xf0106388,(%esp)
f01030ec:	e8 d2 08 00 00       	call   f01039c3 <cprintf>
	uint32_t begin = (uint32_t)ROUNDDOWN(va, PGSIZE);
f01030f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01030f4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va + len, PGSIZE);
f01030fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030fd:	8b 55 10             	mov    0x10(%ebp),%edx
f0103100:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
f0103107:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010310c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i += PGSIZE)
f010310f:	eb 49                	jmp    f010315a <user_mem_check+0x92>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0103111:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0103118:	00 
f0103119:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010311d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103120:	89 04 24             	mov    %eax,(%esp)
f0103123:	e8 56 e0 ff ff       	call   f010117e <pgdir_walk>
		//检测是否有效
		if ((i >= ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm))
f0103128:	85 c0                	test   %eax,%eax
f010312a:	74 14                	je     f0103140 <user_mem_check+0x78>
f010312c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103132:	77 0c                	ja     f0103140 <user_mem_check+0x78>
f0103134:	8b 00                	mov    (%eax),%eax
f0103136:	a8 01                	test   $0x1,%al
f0103138:	74 06                	je     f0103140 <user_mem_check+0x78>
f010313a:	21 f0                	and    %esi,%eax
f010313c:	39 c6                	cmp    %eax,%esi
f010313e:	74 14                	je     f0103154 <user_mem_check+0x8c>
f0103140:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0103143:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
		{		
			//记录无效的地址														 
			user_mem_check_addr = (i < (uint32_t)va ? (uint32_t)va : i); 
f0103147:	89 1d dc e1 17 f0    	mov    %ebx,0xf017e1dc
			return -E_FAULT;
f010314d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103152:	eb 2a                	jmp    f010317e <user_mem_check+0xb6>
	// LAB 3: Your code here.
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
	uint32_t begin = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va + len, PGSIZE);
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i += PGSIZE)
f0103154:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010315a:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010315d:	72 b2                	jb     f0103111 <user_mem_check+0x49>
			//记录无效的地址														 
			user_mem_check_addr = (i < (uint32_t)va ? (uint32_t)va : i); 
			return -E_FAULT;
		}
	}
	cprintf("user_mem_check success va: %x, len: %x\n", va, len);
f010315f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103162:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103166:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103169:	89 44 24 04          	mov    %eax,0x4(%esp)
f010316d:	c7 04 24 a8 63 10 f0 	movl   $0xf01063a8,(%esp)
f0103174:	e8 4a 08 00 00       	call   f01039c3 <cprintf>
	return 0;
f0103179:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010317e:	83 c4 1c             	add    $0x1c,%esp
f0103181:	5b                   	pop    %ebx
f0103182:	5e                   	pop    %esi
f0103183:	5f                   	pop    %edi
f0103184:	5d                   	pop    %ebp
f0103185:	c3                   	ret    

f0103186 <user_mem_assert>:
// If it can, then the function simply returns.
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103186:	55                   	push   %ebp
f0103187:	89 e5                	mov    %esp,%ebp
f0103189:	53                   	push   %ebx
f010318a:	83 ec 14             	sub    $0x14,%esp
f010318d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0)
f0103190:	8b 45 14             	mov    0x14(%ebp),%eax
f0103193:	83 c8 04             	or     $0x4,%eax
f0103196:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010319a:	8b 45 10             	mov    0x10(%ebp),%eax
f010319d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031a8:	89 1c 24             	mov    %ebx,(%esp)
f01031ab:	e8 18 ff ff ff       	call   f01030c8 <user_mem_check>
f01031b0:	85 c0                	test   %eax,%eax
f01031b2:	79 24                	jns    f01031d8 <user_mem_assert+0x52>
	{
		cprintf("[%08x] user_mem_check assertion failure for "
f01031b4:	a1 dc e1 17 f0       	mov    0xf017e1dc,%eax
f01031b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031bd:	8b 43 48             	mov    0x48(%ebx),%eax
f01031c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031c4:	c7 04 24 d0 63 10 f0 	movl   $0xf01063d0,(%esp)
f01031cb:	e8 f3 07 00 00       	call   f01039c3 <cprintf>
				"va %08x\n",
				env->env_id, user_mem_check_addr);
		env_destroy(env); // may not return
f01031d0:	89 1c 24             	mov    %ebx,(%esp)
f01031d3:	e8 b8 06 00 00       	call   f0103890 <env_destroy>
	}
}
f01031d8:	83 c4 14             	add    $0x14,%esp
f01031db:	5b                   	pop    %ebx
f01031dc:	5d                   	pop    %ebp
f01031dd:	c3                   	ret    

f01031de <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01031de:	55                   	push   %ebp
f01031df:	89 e5                	mov    %esp,%ebp
f01031e1:	57                   	push   %edi
f01031e2:	56                   	push   %esi
f01031e3:	53                   	push   %ebx
f01031e4:	83 ec 1c             	sub    $0x1c,%esp
f01031e7:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	va = ROUNDDOWN(va, PGSIZE);
f01031e9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01031ef:	89 d6                	mov    %edx,%esi
	len = ROUNDUP(len, PGSIZE);
f01031f1:	8d 99 ff 0f 00 00    	lea    0xfff(%ecx),%ebx
f01031f7:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	struct PageInfo *pp;
	int ret = 0;

	//为进程分配和映射物理内存。
	//分配并映射 va开始虚拟地址 ，长度len 的空间
	for (; len > 0; len -= PGSIZE, va += PGSIZE)
f01031fd:	eb 73                	jmp    f0103272 <region_alloc+0x94>
	{
		pp = page_alloc(0);
f01031ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103206:	e8 85 de ff ff       	call   f0101090 <page_alloc>

		if (!pp)
f010320b:	85 c0                	test   %eax,%eax
f010320d:	75 1c                	jne    f010322b <region_alloc+0x4d>
		{
			panic("region_alloc failed!\n");
f010320f:	c7 44 24 08 05 64 10 	movl   $0xf0106405,0x8(%esp)
f0103216:	f0 
f0103217:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f010321e:	00 
f010321f:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f0103226:	e8 8b ce ff ff       	call   f01000b6 <_panic>
		}

		ret = page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W);
f010322b:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103232:	00 
f0103233:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103237:	89 44 24 04          	mov    %eax,0x4(%esp)
f010323b:	8b 47 5c             	mov    0x5c(%edi),%eax
f010323e:	89 04 24             	mov    %eax,(%esp)
f0103241:	e8 1f e1 ff ff       	call   f0101365 <page_insert>

		if (ret)
f0103246:	85 c0                	test   %eax,%eax
f0103248:	74 1c                	je     f0103266 <region_alloc+0x88>
		{
			panic("region_alloc failed!\n");
f010324a:	c7 44 24 08 05 64 10 	movl   $0xf0106405,0x8(%esp)
f0103251:	f0 
f0103252:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
f0103259:	00 
f010325a:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f0103261:	e8 50 ce ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp;
	int ret = 0;

	//为进程分配和映射物理内存。
	//分配并映射 va开始虚拟地址 ，长度len 的空间
	for (; len > 0; len -= PGSIZE, va += PGSIZE)
f0103266:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
f010326c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103272:	85 db                	test   %ebx,%ebx
f0103274:	75 89                	jne    f01031ff <region_alloc+0x21>
		if (ret)
		{
			panic("region_alloc failed!\n");
		}
	}
}
f0103276:	83 c4 1c             	add    $0x1c,%esp
f0103279:	5b                   	pop    %ebx
f010327a:	5e                   	pop    %esi
f010327b:	5f                   	pop    %edi
f010327c:	5d                   	pop    %ebp
f010327d:	c3                   	ret    

f010327e <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010327e:	55                   	push   %ebp
f010327f:	89 e5                	mov    %esp,%ebp
f0103281:	8b 45 08             	mov    0x8(%ebp),%eax
f0103284:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0)
f0103287:	85 c0                	test   %eax,%eax
f0103289:	75 11                	jne    f010329c <envid2env+0x1e>
	{
		*env_store = curenv;
f010328b:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103290:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103293:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103295:	b8 00 00 00 00       	mov    $0x0,%eax
f010329a:	eb 5e                	jmp    f01032fa <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010329c:	89 c2                	mov    %eax,%edx
f010329e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01032a4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01032a7:	c1 e2 05             	shl    $0x5,%edx
f01032aa:	03 15 ec e1 17 f0    	add    0xf017e1ec,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid)
f01032b0:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f01032b4:	74 05                	je     f01032bb <envid2env+0x3d>
f01032b6:	39 42 48             	cmp    %eax,0x48(%edx)
f01032b9:	74 10                	je     f01032cb <envid2env+0x4d>
	{
		*env_store = 0;
f01032bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032be:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032c4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032c9:	eb 2f                	jmp    f01032fa <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id)
f01032cb:	84 c9                	test   %cl,%cl
f01032cd:	74 21                	je     f01032f0 <envid2env+0x72>
f01032cf:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01032d4:	39 c2                	cmp    %eax,%edx
f01032d6:	74 18                	je     f01032f0 <envid2env+0x72>
f01032d8:	8b 40 48             	mov    0x48(%eax),%eax
f01032db:	39 42 4c             	cmp    %eax,0x4c(%edx)
f01032de:	74 10                	je     f01032f0 <envid2env+0x72>
	{
		*env_store = 0;
f01032e0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032e3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01032e9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01032ee:	eb 0a                	jmp    f01032fa <envid2env+0x7c>
	}

	*env_store = e;
f01032f0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032f3:	89 10                	mov    %edx,(%eax)
	return 0;
f01032f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032fa:	5d                   	pop    %ebp
f01032fb:	c3                   	ret    

f01032fc <env_init_percpu>:
	env_init_percpu();
}

// Load GDT and segment descriptors.
void env_init_percpu(void)
{
f01032fc:	55                   	push   %ebp
f01032fd:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01032ff:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0103304:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" ::"a"(GD_UD | 3));
f0103307:	b8 23 00 00 00       	mov    $0x23,%eax
f010330c:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" ::"a"(GD_UD | 3));
f010330e:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" ::"a"(GD_KD));
f0103310:	b0 10                	mov    $0x10,%al
f0103312:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" ::"a"(GD_KD));
f0103314:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" ::"a"(GD_KD));
f0103316:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" ::"i"(GD_KT));
f0103318:	ea 1f 33 10 f0 08 00 	ljmp   $0x8,$0xf010331f
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f010331f:	b0 00                	mov    $0x0,%al
f0103321:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103324:	5d                   	pop    %ebp
f0103325:	c3                   	ret    

f0103326 <env_init>:
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void env_init(void)
{
f0103326:	55                   	push   %ebp
f0103327:	89 e5                	mov    %esp,%ebp
f0103329:	56                   	push   %esi
f010332a:	53                   	push   %ebx
	//初始化 env
	env_free_list = NULL;
	int i;
	for (i = NENV - 1; i >= 0; i--)
	{
		envs[i].env_id = 0;
f010332b:	8b 35 ec e1 17 f0    	mov    0xf017e1ec,%esi
f0103331:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0103337:	ba 00 04 00 00       	mov    $0x400,%edx
f010333c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103341:	89 c3                	mov    %eax,%ebx
f0103343:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_parent_id = 0;
f010334a:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		envs[i].env_type = ENV_TYPE_USER;
f0103351:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
		envs[i].env_status = ENV_FREE;
f0103358:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_runs = 0;
f010335f:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
		envs[i].env_pgdir = NULL;
f0103366:	c7 40 5c 00 00 00 00 	movl   $0x0,0x5c(%eax)
		envs[i].env_link = env_free_list;
f010336d:	89 48 44             	mov    %ecx,0x44(%eax)
f0103370:	83 e8 60             	sub    $0x60,%eax
	//init the list

	//初始化 env
	env_free_list = NULL;
	int i;
	for (i = NENV - 1; i >= 0; i--)
f0103373:	83 ea 01             	sub    $0x1,%edx
f0103376:	74 04                	je     f010337c <env_init+0x56>
		envs[i].env_runs = 0;
		envs[i].env_pgdir = NULL;
		envs[i].env_link = env_free_list;

		// 使env_free_list指向envs[0];
		env_free_list = &envs[i];
f0103378:	89 d9                	mov    %ebx,%ecx
f010337a:	eb c5                	jmp    f0103341 <env_init+0x1b>
f010337c:	89 35 f0 e1 17 f0    	mov    %esi,0xf017e1f0
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103382:	e8 75 ff ff ff       	call   f01032fc <env_init_percpu>
}
f0103387:	5b                   	pop    %ebx
f0103388:	5e                   	pop    %esi
f0103389:	5d                   	pop    %ebp
f010338a:	c3                   	ret    

f010338b <env_alloc>:
// Returns 0 on success, < 0 on failure.  Errors include:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010338b:	55                   	push   %ebp
f010338c:	89 e5                	mov    %esp,%ebp
f010338e:	57                   	push   %edi
f010338f:	56                   	push   %esi
f0103390:	53                   	push   %ebx
f0103391:	83 ec 1c             	sub    $0x1c,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103394:	8b 1d f0 e1 17 f0    	mov    0xf017e1f0,%ebx
f010339a:	85 db                	test   %ebx,%ebx
f010339c:	0f 84 60 01 00 00    	je     f0103502 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01033a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01033a9:	e8 e2 dc ff ff       	call   f0101090 <page_alloc>
f01033ae:	85 c0                	test   %eax,%eax
f01033b0:	0f 84 53 01 00 00    	je     f0103509 <env_alloc+0x17e>
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.

	//为新的env 初始化目录页
	(p->pp_ref)++;
f01033b6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01033bb:	2b 05 ac ee 17 f0    	sub    0xf017eeac,%eax
f01033c1:	c1 f8 03             	sar    $0x3,%eax
f01033c4:	c1 e0 0c             	shl    $0xc,%eax
f01033c7:	89 c7                	mov    %eax,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033c9:	c1 e8 0c             	shr    $0xc,%eax
f01033cc:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f01033d2:	72 20                	jb     f01033f4 <env_alloc+0x69>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033d4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01033d8:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f01033df:	f0 
f01033e0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01033e7:	00 
f01033e8:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01033ef:	e8 c2 cc ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01033f4:	8d b7 00 00 00 f0    	lea    -0x10000000(%edi),%esi
	pde_t *page_dir = page2kva(p);
	memcpy(page_dir, kern_pgdir, PGSIZE);
f01033fa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103401:	00 
f0103402:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
f0103407:	89 44 24 04          	mov    %eax,0x4(%esp)
f010340b:	89 34 24             	mov    %esi,(%esp)
f010340e:	e8 69 1a 00 00       	call   f0104e7c <memcpy>
	e->env_pgdir = page_dir;
f0103413:	89 73 5c             	mov    %esi,0x5c(%ebx)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103416:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010341c:	77 20                	ja     f010343e <env_alloc+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010341e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103422:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f0103429:	f0 
f010342a:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
f0103431:	00 
f0103432:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f0103439:	e8 78 cc ff ff       	call   f01000b6 <_panic>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010343e:	83 cf 05             	or     $0x5,%edi
f0103441:	89 be f4 0e 00 00    	mov    %edi,0xef4(%esi)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103447:	8b 43 48             	mov    0x48(%ebx),%eax
f010344a:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0) // Don't create a negative env_id.
f010344f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103454:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103459:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010345c:	89 da                	mov    %ebx,%edx
f010345e:	2b 15 ec e1 17 f0    	sub    0xf017e1ec,%edx
f0103464:	c1 fa 05             	sar    $0x5,%edx
f0103467:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010346d:	09 d0                	or     %edx,%eax
f010346f:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103472:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103475:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103478:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010347f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103486:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010348d:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103494:	00 
f0103495:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010349c:	00 
f010349d:	89 1c 24             	mov    %ebx,(%esp)
f01034a0:	e8 22 19 00 00       	call   f0104dc7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01034a5:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01034ab:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01034b1:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01034b7:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01034be:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01034c4:	8b 43 44             	mov    0x44(%ebx),%eax
f01034c7:	a3 f0 e1 17 f0       	mov    %eax,0xf017e1f0
	*newenv_store = e;
f01034cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01034cf:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034d1:	8b 53 48             	mov    0x48(%ebx),%edx
f01034d4:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01034d9:	85 c0                	test   %eax,%eax
f01034db:	74 05                	je     f01034e2 <env_alloc+0x157>
f01034dd:	8b 40 48             	mov    0x48(%eax),%eax
f01034e0:	eb 05                	jmp    f01034e7 <env_alloc+0x15c>
f01034e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01034eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034ef:	c7 04 24 26 64 10 f0 	movl   $0xf0106426,(%esp)
f01034f6:	e8 c8 04 00 00       	call   f01039c3 <cprintf>
	return 0;
f01034fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103500:	eb 0c                	jmp    f010350e <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103502:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103507:	eb 05                	jmp    f010350e <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103509:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010350e:	83 c4 1c             	add    $0x1c,%esp
f0103511:	5b                   	pop    %ebx
f0103512:	5e                   	pop    %esi
f0103513:	5f                   	pop    %edi
f0103514:	5d                   	pop    %ebp
f0103515:	c3                   	ret    

f0103516 <env_create>:
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void env_create(uint8_t *binary, enum EnvType type)
{
f0103516:	55                   	push   %ebp
f0103517:	89 e5                	mov    %esp,%ebp
f0103519:	57                   	push   %edi
f010351a:	56                   	push   %esi
f010351b:	53                   	push   %ebx
f010351c:	83 ec 3c             	sub    $0x3c,%esp
f010351f:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.

	//通过调用 env_alloc 分配一个新进程，
	int ret = 0;
	struct Env *e = NULL;
f0103522:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ret = env_alloc(&e, 0);
f0103529:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103530:	00 
f0103531:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103534:	89 04 24             	mov    %eax,(%esp)
f0103537:	e8 4f fe ff ff       	call   f010338b <env_alloc>
	if (ret < 0)
f010353c:	85 c0                	test   %eax,%eax
f010353e:	79 24                	jns    f0103564 <env_create+0x4e>
	{
		//r=-E_NO_MEM;
		panic("env_create: %e\n", -E_NO_MEM);
f0103540:	c7 44 24 0c fc ff ff 	movl   $0xfffffffc,0xc(%esp)
f0103547:	ff 
f0103548:	c7 44 24 08 3b 64 10 	movl   $0xf010643b,0x8(%esp)
f010354f:	f0 
f0103550:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f0103557:	00 
f0103558:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f010355f:	e8 52 cb ff ff       	call   f01000b6 <_panic>
	}

	//并调用 load_icode 读入 ELF 二进制映像。
	load_icode(e, binary);
f0103564:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103567:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.

	//处理 ELF 二进制映像
	struct Elf *elfhdr = (struct Elf *)binary;
	struct Proghdr *ph, *eph;
	if (elfhdr->e_magic != ELF_MAGIC)
f010356a:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103570:	74 1c                	je     f010358e <env_create+0x78>
	{
		panic("elf header's magic is not correct\n");
f0103572:	c7 44 24 08 70 64 10 	movl   $0xf0106470,0x8(%esp)
f0103579:	f0 
f010357a:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f0103581:	00 
f0103582:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f0103589:	e8 28 cb ff ff       	call   f01000b6 <_panic>
	}

	ph = (struct Proghdr *)((uint8_t *)elfhdr + elfhdr->e_phoff);
f010358e:	89 fb                	mov    %edi,%ebx
f0103590:	03 5f 1c             	add    0x1c(%edi),%ebx

	eph = ph + elfhdr->e_phnum;
f0103593:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103597:	c1 e6 05             	shl    $0x5,%esi
f010359a:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f010359c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010359f:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01035a2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035a7:	77 20                	ja     f01035c9 <env_create+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035ad:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f01035b4:	f0 
f01035b5:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f01035bc:	00 
f01035bd:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f01035c4:	e8 ed ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01035c9:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01035ce:	0f 22 d8             	mov    %eax,%cr3
f01035d1:	eb 71                	jmp    f0103644 <env_create+0x12e>

	//将映像内容读入新进程的用户地址空间
	for (; ph < eph; ph++)
	{
		if (ph->p_type != ELF_PROG_LOAD)
f01035d3:	83 3b 01             	cmpl   $0x1,(%ebx)
f01035d6:	75 69                	jne    f0103641 <env_create+0x12b>
		{
			continue;
		}

		if (ph->p_filesz > ph->p_memsz)
f01035d8:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01035db:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01035de:	76 1c                	jbe    f01035fc <env_create+0xe6>
		{
			panic("file size is great than memory size\n");
f01035e0:	c7 44 24 08 94 64 10 	movl   $0xf0106494,0x8(%esp)
f01035e7:	f0 
f01035e8:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f01035ef:	00 
f01035f0:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f01035f7:	e8 ba ca ff ff       	call   f01000b6 <_panic>
		}

		region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01035fc:	8b 53 08             	mov    0x8(%ebx),%edx
f01035ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103602:	e8 d7 fb ff ff       	call   f01031de <region_alloc>
		memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103607:	8b 43 10             	mov    0x10(%ebx),%eax
f010360a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010360e:	89 f8                	mov    %edi,%eax
f0103610:	03 43 04             	add    0x4(%ebx),%eax
f0103613:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103617:	8b 43 08             	mov    0x8(%ebx),%eax
f010361a:	89 04 24             	mov    %eax,(%esp)
f010361d:	e8 f2 17 00 00       	call   f0104e14 <memmove>
		memset((void *)ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
f0103622:	8b 43 10             	mov    0x10(%ebx),%eax
f0103625:	8b 53 14             	mov    0x14(%ebx),%edx
f0103628:	29 c2                	sub    %eax,%edx
f010362a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010362e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103635:	00 
f0103636:	03 43 08             	add    0x8(%ebx),%eax
f0103639:	89 04 24             	mov    %eax,(%esp)
f010363c:	e8 86 17 00 00       	call   f0104dc7 <memset>
	eph = ph + elfhdr->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	//将映像内容读入新进程的用户地址空间
	for (; ph < eph; ph++)
f0103641:	83 c3 20             	add    $0x20,%ebx
f0103644:	39 de                	cmp    %ebx,%esi
f0103646:	77 8b                	ja     f01035d3 <env_create+0xbd>
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);
		memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
		memset((void *)ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
	}

	e->env_tf.tf_eip = elfhdr->e_entry;	
f0103648:	8b 47 18             	mov    0x18(%edi),%eax
f010364b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010364e:	89 47 30             	mov    %eax,0x30(%edi)

	lcr3(PADDR(kern_pgdir));
f0103651:	a1 a8 ee 17 f0       	mov    0xf017eea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103656:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010365b:	77 20                	ja     f010367d <env_create+0x167>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010365d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103661:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f0103668:	f0 
f0103669:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
f0103670:	00 
f0103671:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f0103678:	e8 39 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010367d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103682:	0f 22 d8             	mov    %eax,%cr3

	region_alloc(e, (void *)USTACKTOP - PGSIZE, PGSIZE);
f0103685:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010368a:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010368f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103692:	e8 47 fb ff ff       	call   f01031de <region_alloc>
		panic("env_create: %e\n", -E_NO_MEM);
	}

	//并调用 load_icode 读入 ELF 二进制映像。
	load_icode(e, binary);
	e->env_type = type;
f0103697:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010369a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010369d:	89 50 50             	mov    %edx,0x50(%eax)
}
f01036a0:	83 c4 3c             	add    $0x3c,%esp
f01036a3:	5b                   	pop    %ebx
f01036a4:	5e                   	pop    %esi
f01036a5:	5f                   	pop    %edi
f01036a6:	5d                   	pop    %ebp
f01036a7:	c3                   	ret    

f01036a8 <env_free>:

//
// Frees env e and all memory it uses.
//
void env_free(struct Env *e)
{
f01036a8:	55                   	push   %ebp
f01036a9:	89 e5                	mov    %esp,%ebp
f01036ab:	57                   	push   %edi
f01036ac:	56                   	push   %esi
f01036ad:	53                   	push   %ebx
f01036ae:	83 ec 2c             	sub    $0x2c,%esp
f01036b1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01036b4:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01036b9:	39 c7                	cmp    %eax,%edi
f01036bb:	75 37                	jne    f01036f4 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f01036bd:	8b 15 a8 ee 17 f0    	mov    0xf017eea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036c3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01036c9:	77 20                	ja     f01036eb <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01036cf:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f01036d6:	f0 
f01036d7:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f01036de:	00 
f01036df:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f01036e6:	e8 cb c9 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036eb:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01036f1:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01036f4:	8b 57 48             	mov    0x48(%edi),%edx
f01036f7:	85 c0                	test   %eax,%eax
f01036f9:	74 05                	je     f0103700 <env_free+0x58>
f01036fb:	8b 40 48             	mov    0x48(%eax),%eax
f01036fe:	eb 05                	jmp    f0103705 <env_free+0x5d>
f0103700:	b8 00 00 00 00       	mov    $0x0,%eax
f0103705:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103709:	89 44 24 04          	mov    %eax,0x4(%esp)
f010370d:	c7 04 24 4b 64 10 f0 	movl   $0xf010644b,(%esp)
f0103714:	e8 aa 02 00 00       	call   f01039c3 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++)
f0103719:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103720:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103723:	89 c8                	mov    %ecx,%eax
f0103725:	c1 e0 02             	shl    $0x2,%eax
f0103728:	89 45 dc             	mov    %eax,-0x24(%ebp)
	{

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010372b:	8b 47 5c             	mov    0x5c(%edi),%eax
f010372e:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103731:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103737:	0f 84 b7 00 00 00    	je     f01037f4 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010373d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103743:	89 f0                	mov    %esi,%eax
f0103745:	c1 e8 0c             	shr    $0xc,%eax
f0103748:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010374b:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0103751:	72 20                	jb     f0103773 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103753:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103757:	c7 44 24 08 4c 5b 10 	movl   $0xf0105b4c,0x8(%esp)
f010375e:	f0 
f010375f:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
f0103766:	00 
f0103767:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f010376e:	e8 43 c9 ff ff       	call   f01000b6 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
		{
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103773:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103776:	c1 e0 16             	shl    $0x16,%eax
f0103779:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *)KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
f010377c:	bb 00 00 00 00       	mov    $0x0,%ebx
		{
			if (pt[pteno] & PTE_P)
f0103781:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103788:	01 
f0103789:	74 17                	je     f01037a2 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010378b:	89 d8                	mov    %ebx,%eax
f010378d:	c1 e0 0c             	shl    $0xc,%eax
f0103790:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103793:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103797:	8b 47 5c             	mov    0x5c(%edi),%eax
f010379a:	89 04 24             	mov    %eax,(%esp)
f010379d:	e8 85 db ff ff       	call   f0101327 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *)KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
f01037a2:	83 c3 01             	add    $0x1,%ebx
f01037a5:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01037ab:	75 d4                	jne    f0103781 <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01037ad:	8b 47 5c             	mov    0x5c(%edi),%eax
f01037b0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01037b3:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01037ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01037bd:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f01037c3:	72 1c                	jb     f01037e1 <env_free+0x139>
		panic("pa2page called with invalid pa");
f01037c5:	c7 44 24 08 88 5c 10 	movl   $0xf0105c88,0x8(%esp)
f01037cc:	f0 
f01037cd:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01037d4:	00 
f01037d5:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f01037dc:	e8 d5 c8 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01037e1:	a1 ac ee 17 f0       	mov    0xf017eeac,%eax
f01037e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037e9:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f01037ec:	89 04 24             	mov    %eax,(%esp)
f01037ef:	e8 67 d9 ff ff       	call   f010115b <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++)
f01037f4:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01037f8:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01037ff:	0f 85 1b ff ff ff    	jne    f0103720 <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103805:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103808:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010380d:	77 20                	ja     f010382f <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010380f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103813:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f010381a:	f0 
f010381b:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
f0103822:	00 
f0103823:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f010382a:	e8 87 c8 ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f010382f:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103836:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010383b:	c1 e8 0c             	shr    $0xc,%eax
f010383e:	3b 05 a4 ee 17 f0    	cmp    0xf017eea4,%eax
f0103844:	72 1c                	jb     f0103862 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103846:	c7 44 24 08 88 5c 10 	movl   $0xf0105c88,0x8(%esp)
f010384d:	f0 
f010384e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103855:	00 
f0103856:	c7 04 24 cc 58 10 f0 	movl   $0xf01058cc,(%esp)
f010385d:	e8 54 c8 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103862:	8b 15 ac ee 17 f0    	mov    0xf017eeac,%edx
f0103868:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f010386b:	89 04 24             	mov    %eax,(%esp)
f010386e:	e8 e8 d8 ff ff       	call   f010115b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103873:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010387a:	a1 f0 e1 17 f0       	mov    0xf017e1f0,%eax
f010387f:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103882:	89 3d f0 e1 17 f0    	mov    %edi,0xf017e1f0
}
f0103888:	83 c4 2c             	add    $0x2c,%esp
f010388b:	5b                   	pop    %ebx
f010388c:	5e                   	pop    %esi
f010388d:	5f                   	pop    %edi
f010388e:	5d                   	pop    %ebp
f010388f:	c3                   	ret    

f0103890 <env_destroy>:

//
// Frees environment e.
//
void env_destroy(struct Env *e)
{
f0103890:	55                   	push   %ebp
f0103891:	89 e5                	mov    %esp,%ebp
f0103893:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103896:	8b 45 08             	mov    0x8(%ebp),%eax
f0103899:	89 04 24             	mov    %eax,(%esp)
f010389c:	e8 07 fe ff ff       	call   f01036a8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01038a1:	c7 04 24 bc 64 10 f0 	movl   $0xf01064bc,(%esp)
f01038a8:	e8 16 01 00 00       	call   f01039c3 <cprintf>
	while (1)
		monitor(NULL);
f01038ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01038b4:	e8 e2 d0 ff ff       	call   f010099b <monitor>
f01038b9:	eb f2                	jmp    f01038ad <env_destroy+0x1d>

f01038bb <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
//
// This function does not return.
//
void env_pop_tf(struct Trapframe *tf)
{
f01038bb:	55                   	push   %ebp
f01038bc:	89 e5                	mov    %esp,%ebp
f01038be:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f01038c1:	8b 65 08             	mov    0x8(%ebp),%esp
f01038c4:	61                   	popa   
f01038c5:	07                   	pop    %es
f01038c6:	1f                   	pop    %ds
f01038c7:	83 c4 08             	add    $0x8,%esp
f01038ca:	cf                   	iret   
					 "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
					 "\tiret"
					 :
					 : "g"(tf)
					 : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f01038cb:	c7 44 24 08 61 64 10 	movl   $0xf0106461,0x8(%esp)
f01038d2:	f0 
f01038d3:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
f01038da:	00 
f01038db:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f01038e2:	e8 cf c7 ff ff       	call   f01000b6 <_panic>

f01038e7 <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//
// This function does not return.
//
void env_run(struct Env *e)
{
f01038e7:	55                   	push   %ebp
f01038e8:	89 e5                	mov    %esp,%ebp
f01038ea:	83 ec 18             	sub    $0x18,%esp
f01038ed:	8b 45 08             	mov    0x8(%ebp),%eax
	// 启动给定的在用户模式运行的进程

	//panic("env_run not yet implemented");

	//停止当前进程
	if (curenv && curenv->env_status == ENV_RUNNING)
f01038f0:	8b 15 e8 e1 17 f0    	mov    0xf017e1e8,%edx
f01038f6:	85 d2                	test   %edx,%edx
f01038f8:	74 0d                	je     f0103907 <env_run+0x20>
f01038fa:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f01038fe:	75 07                	jne    f0103907 <env_run+0x20>
	{
		curenv->env_status = ENV_RUNNABLE;
f0103900:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	//current 指向当前进程
	curenv = e;
f0103907:	a3 e8 e1 17 f0       	mov    %eax,0xf017e1e8
	e->env_status = ENV_RUNNING;
f010390c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0103913:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0103917:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010391a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103920:	77 20                	ja     f0103942 <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103922:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103926:	c7 44 24 08 e4 5c 10 	movl   $0xf0105ce4,0x8(%esp)
f010392d:	f0 
f010392e:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0103935:	00 
f0103936:	c7 04 24 1b 64 10 f0 	movl   $0xf010641b,(%esp)
f010393d:	e8 74 c7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103942:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103948:	0f 22 da             	mov    %edx,%cr3
	//进程切换
	env_pop_tf(&(e->env_tf));
f010394b:	89 04 24             	mov    %eax,(%esp)
f010394e:	e8 68 ff ff ff       	call   f01038bb <env_pop_tf>

f0103953 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103953:	55                   	push   %ebp
f0103954:	89 e5                	mov    %esp,%ebp
f0103956:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010395a:	ba 70 00 00 00       	mov    $0x70,%edx
f010395f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103960:	b2 71                	mov    $0x71,%dl
f0103962:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103963:	0f b6 c0             	movzbl %al,%eax
}
f0103966:	5d                   	pop    %ebp
f0103967:	c3                   	ret    

f0103968 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103968:	55                   	push   %ebp
f0103969:	89 e5                	mov    %esp,%ebp
f010396b:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010396f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103974:	ee                   	out    %al,(%dx)
f0103975:	b2 71                	mov    $0x71,%dl
f0103977:	8b 45 0c             	mov    0xc(%ebp),%eax
f010397a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010397b:	5d                   	pop    %ebp
f010397c:	c3                   	ret    

f010397d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010397d:	55                   	push   %ebp
f010397e:	89 e5                	mov    %esp,%ebp
f0103980:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103983:	8b 45 08             	mov    0x8(%ebp),%eax
f0103986:	89 04 24             	mov    %eax,(%esp)
f0103989:	e8 83 cc ff ff       	call   f0100611 <cputchar>
	*cnt++;
}
f010398e:	c9                   	leave  
f010398f:	c3                   	ret    

f0103990 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103990:	55                   	push   %ebp
f0103991:	89 e5                	mov    %esp,%ebp
f0103993:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103996:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010399d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01039a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01039a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01039ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039b2:	c7 04 24 7d 39 10 f0 	movl   $0xf010397d,(%esp)
f01039b9:	e8 50 0d 00 00       	call   f010470e <vprintfmt>
	return cnt;
}
f01039be:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039c1:	c9                   	leave  
f01039c2:	c3                   	ret    

f01039c3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01039c3:	55                   	push   %ebp
f01039c4:	89 e5                	mov    %esp,%ebp
f01039c6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01039c9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01039cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039d3:	89 04 24             	mov    %eax,(%esp)
f01039d6:	e8 b5 ff ff ff       	call   f0103990 <vcprintf>
	va_end(ap);

	return cnt;
}
f01039db:	c9                   	leave  
f01039dc:	c3                   	ret    
f01039dd:	66 90                	xchg   %ax,%ax
f01039df:	90                   	nop

f01039e0 <trap_init_percpu>:
	trap_init_percpu();
}

// Initialize and load the per-CPU TSS and IDT
void trap_init_percpu(void)
{
f01039e0:	55                   	push   %ebp
f01039e1:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01039e3:	c7 05 24 ea 17 f0 00 	movl   $0xf0000000,0xf017ea24
f01039ea:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01039ed:	66 c7 05 28 ea 17 f0 	movw   $0x10,0xf017ea28
f01039f4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t)(&ts),
f01039f6:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f01039fd:	67 00 
f01039ff:	b8 20 ea 17 f0       	mov    $0xf017ea20,%eax
f0103a04:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f0103a0a:	89 c2                	mov    %eax,%edx
f0103a0c:	c1 ea 10             	shr    $0x10,%edx
f0103a0f:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f0103a15:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f0103a1c:	c1 e8 18             	shr    $0x18,%eax
f0103a1f:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
							  sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103a24:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103a2b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103a30:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103a33:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f0103a38:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103a3b:	5d                   	pop    %ebp
f0103a3c:	c3                   	ret    

f0103a3d <trap_init>:
		return "System call";
	return "(unknown trap)";
}

void trap_init(void)
{
f0103a3d:	55                   	push   %ebp
f0103a3e:	89 e5                	mov    %esp,%ebp
	//将异常处理函数 与 对应的代码段sel 关联
	//sel代码段选择
	//off偏移
	//dpl特权位
	//定义在inc/mmu.h
	SETGATE(idt[0], 0, GD_KT, th0, 0);
f0103a40:	b8 f2 40 10 f0       	mov    $0xf01040f2,%eax
f0103a45:	66 a3 00 e2 17 f0    	mov    %ax,0xf017e200
f0103a4b:	66 c7 05 02 e2 17 f0 	movw   $0x8,0xf017e202
f0103a52:	08 00 
f0103a54:	c6 05 04 e2 17 f0 00 	movb   $0x0,0xf017e204
f0103a5b:	c6 05 05 e2 17 f0 8e 	movb   $0x8e,0xf017e205
f0103a62:	c1 e8 10             	shr    $0x10,%eax
f0103a65:	66 a3 06 e2 17 f0    	mov    %ax,0xf017e206
	SETGATE(idt[1], 0, GD_KT, th1, 0);
f0103a6b:	b8 f8 40 10 f0       	mov    $0xf01040f8,%eax
f0103a70:	66 a3 08 e2 17 f0    	mov    %ax,0xf017e208
f0103a76:	66 c7 05 0a e2 17 f0 	movw   $0x8,0xf017e20a
f0103a7d:	08 00 
f0103a7f:	c6 05 0c e2 17 f0 00 	movb   $0x0,0xf017e20c
f0103a86:	c6 05 0d e2 17 f0 8e 	movb   $0x8e,0xf017e20d
f0103a8d:	c1 e8 10             	shr    $0x10,%eax
f0103a90:	66 a3 0e e2 17 f0    	mov    %ax,0xf017e20e
	SETGATE(idt[3], 0, GD_KT, th3, 3);
f0103a96:	b8 fe 40 10 f0       	mov    $0xf01040fe,%eax
f0103a9b:	66 a3 18 e2 17 f0    	mov    %ax,0xf017e218
f0103aa1:	66 c7 05 1a e2 17 f0 	movw   $0x8,0xf017e21a
f0103aa8:	08 00 
f0103aaa:	c6 05 1c e2 17 f0 00 	movb   $0x0,0xf017e21c
f0103ab1:	c6 05 1d e2 17 f0 ee 	movb   $0xee,0xf017e21d
f0103ab8:	c1 e8 10             	shr    $0x10,%eax
f0103abb:	66 a3 1e e2 17 f0    	mov    %ax,0xf017e21e
	SETGATE(idt[4], 0, GD_KT, th4, 0);
f0103ac1:	b8 04 41 10 f0       	mov    $0xf0104104,%eax
f0103ac6:	66 a3 20 e2 17 f0    	mov    %ax,0xf017e220
f0103acc:	66 c7 05 22 e2 17 f0 	movw   $0x8,0xf017e222
f0103ad3:	08 00 
f0103ad5:	c6 05 24 e2 17 f0 00 	movb   $0x0,0xf017e224
f0103adc:	c6 05 25 e2 17 f0 8e 	movb   $0x8e,0xf017e225
f0103ae3:	c1 e8 10             	shr    $0x10,%eax
f0103ae6:	66 a3 26 e2 17 f0    	mov    %ax,0xf017e226
	SETGATE(idt[5], 0, GD_KT, th5, 0);
f0103aec:	b8 0a 41 10 f0       	mov    $0xf010410a,%eax
f0103af1:	66 a3 28 e2 17 f0    	mov    %ax,0xf017e228
f0103af7:	66 c7 05 2a e2 17 f0 	movw   $0x8,0xf017e22a
f0103afe:	08 00 
f0103b00:	c6 05 2c e2 17 f0 00 	movb   $0x0,0xf017e22c
f0103b07:	c6 05 2d e2 17 f0 8e 	movb   $0x8e,0xf017e22d
f0103b0e:	c1 e8 10             	shr    $0x10,%eax
f0103b11:	66 a3 2e e2 17 f0    	mov    %ax,0xf017e22e
	SETGATE(idt[6], 0, GD_KT, th6, 0);
f0103b17:	b8 10 41 10 f0       	mov    $0xf0104110,%eax
f0103b1c:	66 a3 30 e2 17 f0    	mov    %ax,0xf017e230
f0103b22:	66 c7 05 32 e2 17 f0 	movw   $0x8,0xf017e232
f0103b29:	08 00 
f0103b2b:	c6 05 34 e2 17 f0 00 	movb   $0x0,0xf017e234
f0103b32:	c6 05 35 e2 17 f0 8e 	movb   $0x8e,0xf017e235
f0103b39:	c1 e8 10             	shr    $0x10,%eax
f0103b3c:	66 a3 36 e2 17 f0    	mov    %ax,0xf017e236
	SETGATE(idt[7], 0, GD_KT, th7, 0);
f0103b42:	b8 16 41 10 f0       	mov    $0xf0104116,%eax
f0103b47:	66 a3 38 e2 17 f0    	mov    %ax,0xf017e238
f0103b4d:	66 c7 05 3a e2 17 f0 	movw   $0x8,0xf017e23a
f0103b54:	08 00 
f0103b56:	c6 05 3c e2 17 f0 00 	movb   $0x0,0xf017e23c
f0103b5d:	c6 05 3d e2 17 f0 8e 	movb   $0x8e,0xf017e23d
f0103b64:	c1 e8 10             	shr    $0x10,%eax
f0103b67:	66 a3 3e e2 17 f0    	mov    %ax,0xf017e23e
	SETGATE(idt[8], 0, GD_KT, th8, 0);
f0103b6d:	b8 1c 41 10 f0       	mov    $0xf010411c,%eax
f0103b72:	66 a3 40 e2 17 f0    	mov    %ax,0xf017e240
f0103b78:	66 c7 05 42 e2 17 f0 	movw   $0x8,0xf017e242
f0103b7f:	08 00 
f0103b81:	c6 05 44 e2 17 f0 00 	movb   $0x0,0xf017e244
f0103b88:	c6 05 45 e2 17 f0 8e 	movb   $0x8e,0xf017e245
f0103b8f:	c1 e8 10             	shr    $0x10,%eax
f0103b92:	66 a3 46 e2 17 f0    	mov    %ax,0xf017e246
	SETGATE(idt[9], 0, GD_KT, th9, 0);
f0103b98:	b8 20 41 10 f0       	mov    $0xf0104120,%eax
f0103b9d:	66 a3 48 e2 17 f0    	mov    %ax,0xf017e248
f0103ba3:	66 c7 05 4a e2 17 f0 	movw   $0x8,0xf017e24a
f0103baa:	08 00 
f0103bac:	c6 05 4c e2 17 f0 00 	movb   $0x0,0xf017e24c
f0103bb3:	c6 05 4d e2 17 f0 8e 	movb   $0x8e,0xf017e24d
f0103bba:	c1 e8 10             	shr    $0x10,%eax
f0103bbd:	66 a3 4e e2 17 f0    	mov    %ax,0xf017e24e
	SETGATE(idt[10], 0, GD_KT, th10, 0);
f0103bc3:	b8 26 41 10 f0       	mov    $0xf0104126,%eax
f0103bc8:	66 a3 50 e2 17 f0    	mov    %ax,0xf017e250
f0103bce:	66 c7 05 52 e2 17 f0 	movw   $0x8,0xf017e252
f0103bd5:	08 00 
f0103bd7:	c6 05 54 e2 17 f0 00 	movb   $0x0,0xf017e254
f0103bde:	c6 05 55 e2 17 f0 8e 	movb   $0x8e,0xf017e255
f0103be5:	c1 e8 10             	shr    $0x10,%eax
f0103be8:	66 a3 56 e2 17 f0    	mov    %ax,0xf017e256
	SETGATE(idt[11], 0, GD_KT, th11, 0);
f0103bee:	b8 2a 41 10 f0       	mov    $0xf010412a,%eax
f0103bf3:	66 a3 58 e2 17 f0    	mov    %ax,0xf017e258
f0103bf9:	66 c7 05 5a e2 17 f0 	movw   $0x8,0xf017e25a
f0103c00:	08 00 
f0103c02:	c6 05 5c e2 17 f0 00 	movb   $0x0,0xf017e25c
f0103c09:	c6 05 5d e2 17 f0 8e 	movb   $0x8e,0xf017e25d
f0103c10:	c1 e8 10             	shr    $0x10,%eax
f0103c13:	66 a3 5e e2 17 f0    	mov    %ax,0xf017e25e
	SETGATE(idt[12], 0, GD_KT, th12, 0);
f0103c19:	b8 2e 41 10 f0       	mov    $0xf010412e,%eax
f0103c1e:	66 a3 60 e2 17 f0    	mov    %ax,0xf017e260
f0103c24:	66 c7 05 62 e2 17 f0 	movw   $0x8,0xf017e262
f0103c2b:	08 00 
f0103c2d:	c6 05 64 e2 17 f0 00 	movb   $0x0,0xf017e264
f0103c34:	c6 05 65 e2 17 f0 8e 	movb   $0x8e,0xf017e265
f0103c3b:	c1 e8 10             	shr    $0x10,%eax
f0103c3e:	66 a3 66 e2 17 f0    	mov    %ax,0xf017e266
	SETGATE(idt[13], 0, GD_KT, th13, 0);
f0103c44:	b8 32 41 10 f0       	mov    $0xf0104132,%eax
f0103c49:	66 a3 68 e2 17 f0    	mov    %ax,0xf017e268
f0103c4f:	66 c7 05 6a e2 17 f0 	movw   $0x8,0xf017e26a
f0103c56:	08 00 
f0103c58:	c6 05 6c e2 17 f0 00 	movb   $0x0,0xf017e26c
f0103c5f:	c6 05 6d e2 17 f0 8e 	movb   $0x8e,0xf017e26d
f0103c66:	c1 e8 10             	shr    $0x10,%eax
f0103c69:	66 a3 6e e2 17 f0    	mov    %ax,0xf017e26e
	SETGATE(idt[14], 0, GD_KT, th14, 0);
f0103c6f:	b8 36 41 10 f0       	mov    $0xf0104136,%eax
f0103c74:	66 a3 70 e2 17 f0    	mov    %ax,0xf017e270
f0103c7a:	66 c7 05 72 e2 17 f0 	movw   $0x8,0xf017e272
f0103c81:	08 00 
f0103c83:	c6 05 74 e2 17 f0 00 	movb   $0x0,0xf017e274
f0103c8a:	c6 05 75 e2 17 f0 8e 	movb   $0x8e,0xf017e275
f0103c91:	c1 e8 10             	shr    $0x10,%eax
f0103c94:	66 a3 76 e2 17 f0    	mov    %ax,0xf017e276
	SETGATE(idt[16], 0, GD_KT, th16, 0);
f0103c9a:	b8 3a 41 10 f0       	mov    $0xf010413a,%eax
f0103c9f:	66 a3 80 e2 17 f0    	mov    %ax,0xf017e280
f0103ca5:	66 c7 05 82 e2 17 f0 	movw   $0x8,0xf017e282
f0103cac:	08 00 
f0103cae:	c6 05 84 e2 17 f0 00 	movb   $0x0,0xf017e284
f0103cb5:	c6 05 85 e2 17 f0 8e 	movb   $0x8e,0xf017e285
f0103cbc:	c1 e8 10             	shr    $0x10,%eax
f0103cbf:	66 a3 86 e2 17 f0    	mov    %ax,0xf017e286
	SETGATE(idt[T_SYSCALL], 0, GD_KT, th_syscall, 3);
f0103cc5:	b8 40 41 10 f0       	mov    $0xf0104140,%eax
f0103cca:	66 a3 80 e3 17 f0    	mov    %ax,0xf017e380
f0103cd0:	66 c7 05 82 e3 17 f0 	movw   $0x8,0xf017e382
f0103cd7:	08 00 
f0103cd9:	c6 05 84 e3 17 f0 00 	movb   $0x0,0xf017e384
f0103ce0:	c6 05 85 e3 17 f0 ee 	movb   $0xee,0xf017e385
f0103ce7:	c1 e8 10             	shr    $0x10,%eax
f0103cea:	66 a3 86 e3 17 f0    	mov    %ax,0xf017e386
	// Per-CPU setup
	trap_init_percpu();
f0103cf0:	e8 eb fc ff ff       	call   f01039e0 <trap_init_percpu>
}
f0103cf5:	5d                   	pop    %ebp
f0103cf6:	c3                   	ret    

f0103cf7 <print_regs>:
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void print_regs(struct PushRegs *regs)
{
f0103cf7:	55                   	push   %ebp
f0103cf8:	89 e5                	mov    %esp,%ebp
f0103cfa:	53                   	push   %ebx
f0103cfb:	83 ec 14             	sub    $0x14,%esp
f0103cfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d01:	8b 03                	mov    (%ebx),%eax
f0103d03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d07:	c7 04 24 f2 64 10 f0 	movl   $0xf01064f2,(%esp)
f0103d0e:	e8 b0 fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d13:	8b 43 04             	mov    0x4(%ebx),%eax
f0103d16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d1a:	c7 04 24 01 65 10 f0 	movl   $0xf0106501,(%esp)
f0103d21:	e8 9d fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103d26:	8b 43 08             	mov    0x8(%ebx),%eax
f0103d29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d2d:	c7 04 24 10 65 10 f0 	movl   $0xf0106510,(%esp)
f0103d34:	e8 8a fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103d39:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103d3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d40:	c7 04 24 1f 65 10 f0 	movl   $0xf010651f,(%esp)
f0103d47:	e8 77 fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103d4c:	8b 43 10             	mov    0x10(%ebx),%eax
f0103d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d53:	c7 04 24 2e 65 10 f0 	movl   $0xf010652e,(%esp)
f0103d5a:	e8 64 fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103d5f:	8b 43 14             	mov    0x14(%ebx),%eax
f0103d62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d66:	c7 04 24 3d 65 10 f0 	movl   $0xf010653d,(%esp)
f0103d6d:	e8 51 fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103d72:	8b 43 18             	mov    0x18(%ebx),%eax
f0103d75:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d79:	c7 04 24 4c 65 10 f0 	movl   $0xf010654c,(%esp)
f0103d80:	e8 3e fc ff ff       	call   f01039c3 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103d85:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103d88:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d8c:	c7 04 24 5b 65 10 f0 	movl   $0xf010655b,(%esp)
f0103d93:	e8 2b fc ff ff       	call   f01039c3 <cprintf>
}
f0103d98:	83 c4 14             	add    $0x14,%esp
f0103d9b:	5b                   	pop    %ebx
f0103d9c:	5d                   	pop    %ebp
f0103d9d:	c3                   	ret    

f0103d9e <print_trapframe>:
	// Load the IDT
	lidt(&idt_pd);
}

void print_trapframe(struct Trapframe *tf)
{
f0103d9e:	55                   	push   %ebp
f0103d9f:	89 e5                	mov    %esp,%ebp
f0103da1:	56                   	push   %esi
f0103da2:	53                   	push   %ebx
f0103da3:	83 ec 10             	sub    $0x10,%esp
f0103da6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103da9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dad:	c7 04 24 91 66 10 f0 	movl   $0xf0106691,(%esp)
f0103db4:	e8 0a fc ff ff       	call   f01039c3 <cprintf>
	print_regs(&tf->tf_regs);
f0103db9:	89 1c 24             	mov    %ebx,(%esp)
f0103dbc:	e8 36 ff ff ff       	call   f0103cf7 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103dc1:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103dc5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dc9:	c7 04 24 ac 65 10 f0 	movl   $0xf01065ac,(%esp)
f0103dd0:	e8 ee fb ff ff       	call   f01039c3 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103dd5:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103dd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ddd:	c7 04 24 bf 65 10 f0 	movl   $0xf01065bf,(%esp)
f0103de4:	e8 da fb ff ff       	call   f01039c3 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103de9:	8b 43 28             	mov    0x28(%ebx),%eax
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"};

	if (trapno < sizeof(excnames) / sizeof(excnames[0]))
f0103dec:	83 f8 13             	cmp    $0x13,%eax
f0103def:	77 09                	ja     f0103dfa <print_trapframe+0x5c>
		return excnames[trapno];
f0103df1:	8b 14 85 a0 68 10 f0 	mov    -0xfef9760(,%eax,4),%edx
f0103df8:	eb 10                	jmp    f0103e0a <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103dfa:	83 f8 30             	cmp    $0x30,%eax
f0103dfd:	ba 6a 65 10 f0       	mov    $0xf010656a,%edx
f0103e02:	b9 76 65 10 f0       	mov    $0xf0106576,%ecx
f0103e07:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e0a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e12:	c7 04 24 d2 65 10 f0 	movl   $0xf01065d2,(%esp)
f0103e19:	e8 a5 fb ff ff       	call   f01039c3 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103e1e:	3b 1d 00 ea 17 f0    	cmp    0xf017ea00,%ebx
f0103e24:	75 19                	jne    f0103e3f <print_trapframe+0xa1>
f0103e26:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103e2a:	75 13                	jne    f0103e3f <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103e2c:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103e2f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e33:	c7 04 24 e4 65 10 f0 	movl   $0xf01065e4,(%esp)
f0103e3a:	e8 84 fb ff ff       	call   f01039c3 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103e3f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103e42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e46:	c7 04 24 f3 65 10 f0 	movl   $0xf01065f3,(%esp)
f0103e4d:	e8 71 fb ff ff       	call   f01039c3 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103e52:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103e56:	75 51                	jne    f0103ea9 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
				tf->tf_err & 4 ? "user" : "kernel",
				tf->tf_err & 2 ? "write" : "read",
				tf->tf_err & 1 ? "protection" : "not-present");
f0103e58:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103e5b:	89 c2                	mov    %eax,%edx
f0103e5d:	83 e2 01             	and    $0x1,%edx
f0103e60:	ba 85 65 10 f0       	mov    $0xf0106585,%edx
f0103e65:	b9 90 65 10 f0       	mov    $0xf0106590,%ecx
f0103e6a:	0f 45 ca             	cmovne %edx,%ecx
f0103e6d:	89 c2                	mov    %eax,%edx
f0103e6f:	83 e2 02             	and    $0x2,%edx
f0103e72:	ba 9c 65 10 f0       	mov    $0xf010659c,%edx
f0103e77:	be a2 65 10 f0       	mov    $0xf01065a2,%esi
f0103e7c:	0f 44 d6             	cmove  %esi,%edx
f0103e7f:	83 e0 04             	and    $0x4,%eax
f0103e82:	b8 a7 65 10 f0       	mov    $0xf01065a7,%eax
f0103e87:	be bc 66 10 f0       	mov    $0xf01066bc,%esi
f0103e8c:	0f 44 c6             	cmove  %esi,%eax
f0103e8f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103e93:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e9b:	c7 04 24 01 66 10 f0 	movl   $0xf0106601,(%esp)
f0103ea2:	e8 1c fb ff ff       	call   f01039c3 <cprintf>
f0103ea7:	eb 0c                	jmp    f0103eb5 <print_trapframe+0x117>
				tf->tf_err & 4 ? "user" : "kernel",
				tf->tf_err & 2 ? "write" : "read",
				tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103ea9:	c7 04 24 65 55 10 f0 	movl   $0xf0105565,(%esp)
f0103eb0:	e8 0e fb ff ff       	call   f01039c3 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103eb5:	8b 43 30             	mov    0x30(%ebx),%eax
f0103eb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ebc:	c7 04 24 10 66 10 f0 	movl   $0xf0106610,(%esp)
f0103ec3:	e8 fb fa ff ff       	call   f01039c3 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ec8:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ecc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ed0:	c7 04 24 1f 66 10 f0 	movl   $0xf010661f,(%esp)
f0103ed7:	e8 e7 fa ff ff       	call   f01039c3 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103edc:	8b 43 38             	mov    0x38(%ebx),%eax
f0103edf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ee3:	c7 04 24 32 66 10 f0 	movl   $0xf0106632,(%esp)
f0103eea:	e8 d4 fa ff ff       	call   f01039c3 <cprintf>
	if ((tf->tf_cs & 3) != 0)
f0103eef:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ef3:	74 27                	je     f0103f1c <print_trapframe+0x17e>
	{
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ef5:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ef8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103efc:	c7 04 24 41 66 10 f0 	movl   $0xf0106641,(%esp)
f0103f03:	e8 bb fa ff ff       	call   f01039c3 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103f08:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103f0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f10:	c7 04 24 50 66 10 f0 	movl   $0xf0106650,(%esp)
f0103f17:	e8 a7 fa ff ff       	call   f01039c3 <cprintf>
	}
}
f0103f1c:	83 c4 10             	add    $0x10,%esp
f0103f1f:	5b                   	pop    %ebx
f0103f20:	5e                   	pop    %esi
f0103f21:	5d                   	pop    %ebp
f0103f22:	c3                   	ret    

f0103f23 <page_fault_handler>:
	assert(curenv && curenv->env_status == ENV_RUNNING);
	env_run(curenv);
}

void page_fault_handler(struct Trapframe *tf)
{
f0103f23:	55                   	push   %ebp
f0103f24:	89 e5                	mov    %esp,%ebp
f0103f26:	53                   	push   %ebx
f0103f27:	83 ec 14             	sub    $0x14,%esp
f0103f2a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f2d:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //内核态发生缺页中断直接panic
f0103f30:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103f34:	75 1c                	jne    f0103f52 <page_fault_handler+0x2f>
		panic("page_fault_handler():page fault in kernel mode!\n");
f0103f36:	c7 44 24 08 08 68 10 	movl   $0xf0106808,0x8(%esp)
f0103f3d:	f0 
f0103f3e:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
f0103f45:	00 
f0103f46:	c7 04 24 63 66 10 f0 	movl   $0xf0106663,(%esp)
f0103f4d:	e8 64 c1 ff ff       	call   f01000b6 <_panic>
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103f52:	8b 53 30             	mov    0x30(%ebx),%edx
f0103f55:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f59:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f5d:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103f62:	8b 40 48             	mov    0x48(%eax),%eax
f0103f65:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f69:	c7 04 24 3c 68 10 f0 	movl   $0xf010683c,(%esp)
f0103f70:	e8 4e fa ff ff       	call   f01039c3 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103f75:	89 1c 24             	mov    %ebx,(%esp)
f0103f78:	e8 21 fe ff ff       	call   f0103d9e <print_trapframe>
	env_destroy(curenv);
f0103f7d:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103f82:	89 04 24             	mov    %eax,(%esp)
f0103f85:	e8 06 f9 ff ff       	call   f0103890 <env_destroy>
}
f0103f8a:	83 c4 14             	add    $0x14,%esp
f0103f8d:	5b                   	pop    %ebx
f0103f8e:	5d                   	pop    %ebp
f0103f8f:	c3                   	ret    

f0103f90 <trap>:
		return;
	}
}

void trap(struct Trapframe *tf)
{
f0103f90:	55                   	push   %ebp
f0103f91:	89 e5                	mov    %esp,%ebp
f0103f93:	57                   	push   %edi
f0103f94:	56                   	push   %esi
f0103f95:	83 ec 20             	sub    $0x20,%esp
f0103f98:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::
f0103f9b:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103f9c:	9c                   	pushf  
f0103f9d:	58                   	pop    %eax
					 : "cc");

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103f9e:	f6 c4 02             	test   $0x2,%ah
f0103fa1:	74 24                	je     f0103fc7 <trap+0x37>
f0103fa3:	c7 44 24 0c 6f 66 10 	movl   $0xf010666f,0xc(%esp)
f0103faa:	f0 
f0103fab:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0103fb2:	f0 
f0103fb3:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f0103fba:	00 
f0103fbb:	c7 04 24 63 66 10 f0 	movl   $0xf0106663,(%esp)
f0103fc2:	e8 ef c0 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103fc7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103fcb:	c7 04 24 88 66 10 f0 	movl   $0xf0106688,(%esp)
f0103fd2:	e8 ec f9 ff ff       	call   f01039c3 <cprintf>

	if ((tf->tf_cs & 3) == 3)
f0103fd7:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103fdb:	83 e0 03             	and    $0x3,%eax
f0103fde:	66 83 f8 03          	cmp    $0x3,%ax
f0103fe2:	75 3c                	jne    f0104020 <trap+0x90>
	{
		// Trapped from user mode.
		assert(curenv);
f0103fe4:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f0103fe9:	85 c0                	test   %eax,%eax
f0103feb:	75 24                	jne    f0104011 <trap+0x81>
f0103fed:	c7 44 24 0c a3 66 10 	movl   $0xf01066a3,0xc(%esp)
f0103ff4:	f0 
f0103ff5:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f0103ffc:	f0 
f0103ffd:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
f0104004:	00 
f0104005:	c7 04 24 63 66 10 f0 	movl   $0xf0106663,(%esp)
f010400c:	e8 a5 c0 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104011:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104016:	89 c7                	mov    %eax,%edi
f0104018:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010401a:	8b 35 e8 e1 17 f0    	mov    0xf017e1e8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104020:	89 35 00 ea 17 f0    	mov    %esi,0xf017ea00
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	//页错误 page_fault_handler
	if (tf->tf_trapno == T_PGFLT)
f0104026:	8b 46 28             	mov    0x28(%esi),%eax
f0104029:	83 f8 0e             	cmp    $0xe,%eax
f010402c:	75 0a                	jne    f0104038 <trap+0xa8>
	{
		page_fault_handler(tf);
f010402e:	89 34 24             	mov    %esi,(%esp)
f0104031:	e8 ed fe ff ff       	call   f0103f23 <page_fault_handler>
f0104036:	eb 7e                	jmp    f01040b6 <trap+0x126>
		return;
	}
	//断点异常 调用监视器
	if (tf->tf_trapno == T_BRKPT)
f0104038:	83 f8 03             	cmp    $0x3,%eax
f010403b:	75 0a                	jne    f0104047 <trap+0xb7>
	{
		monitor(tf);
f010403d:	89 34 24             	mov    %esi,(%esp)
f0104040:	e8 56 c9 ff ff       	call   f010099b <monitor>
f0104045:	eb 6f                	jmp    f01040b6 <trap+0x126>
		return;
	}
	//系统调用 syscall()
	if (tf->tf_trapno == T_SYSCALL)
f0104047:	83 f8 30             	cmp    $0x30,%eax
f010404a:	75 32                	jne    f010407e <trap+0xee>
	{
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f010404c:	8b 46 04             	mov    0x4(%esi),%eax
f010404f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104053:	8b 06                	mov    (%esi),%eax
f0104055:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104059:	8b 46 10             	mov    0x10(%esi),%eax
f010405c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104060:	8b 46 18             	mov    0x18(%esi),%eax
f0104063:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104067:	8b 46 14             	mov    0x14(%esi),%eax
f010406a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010406e:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104071:	89 04 24             	mov    %eax,(%esp)
f0104074:	e8 e7 00 00 00       	call   f0104160 <syscall>
f0104079:	89 46 1c             	mov    %eax,0x1c(%esi)
f010407c:	eb 38                	jmp    f01040b6 <trap+0x126>
									  tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010407e:	89 34 24             	mov    %esi,(%esp)
f0104081:	e8 18 fd ff ff       	call   f0103d9e <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104086:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010408b:	75 1c                	jne    f01040a9 <trap+0x119>
		panic("unhandled trap in kernel");
f010408d:	c7 44 24 08 aa 66 10 	movl   $0xf01066aa,0x8(%esp)
f0104094:	f0 
f0104095:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f010409c:	00 
f010409d:	c7 04 24 63 66 10 f0 	movl   $0xf0106663,(%esp)
f01040a4:	e8 0d c0 ff ff       	call   f01000b6 <_panic>
	else
	{
		env_destroy(curenv);
f01040a9:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01040ae:	89 04 24             	mov    %eax,(%esp)
f01040b1:	e8 da f7 ff ff       	call   f0103890 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01040b6:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01040bb:	85 c0                	test   %eax,%eax
f01040bd:	74 06                	je     f01040c5 <trap+0x135>
f01040bf:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01040c3:	74 24                	je     f01040e9 <trap+0x159>
f01040c5:	c7 44 24 0c 60 68 10 	movl   $0xf0106860,0xc(%esp)
f01040cc:	f0 
f01040cd:	c7 44 24 08 e6 58 10 	movl   $0xf01058e6,0x8(%esp)
f01040d4:	f0 
f01040d5:	c7 44 24 04 f5 00 00 	movl   $0xf5,0x4(%esp)
f01040dc:	00 
f01040dd:	c7 04 24 63 66 10 f0 	movl   $0xf0106663,(%esp)
f01040e4:	e8 cd bf ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f01040e9:	89 04 24             	mov    %eax,(%esp)
f01040ec:	e8 f6 f7 ff ff       	call   f01038e7 <env_run>
f01040f1:	90                   	nop

f01040f2 <th0>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

    //创建0-16中断函数
    TRAPHANDLER_NOEC(th0, 0)
f01040f2:	6a 00                	push   $0x0
f01040f4:	6a 00                	push   $0x0
f01040f6:	eb 4e                	jmp    f0104146 <_alltraps>

f01040f8 <th1>:
    TRAPHANDLER_NOEC(th1, 1)
f01040f8:	6a 00                	push   $0x0
f01040fa:	6a 01                	push   $0x1
f01040fc:	eb 48                	jmp    f0104146 <_alltraps>

f01040fe <th3>:
    TRAPHANDLER_NOEC(th3, 3)
f01040fe:	6a 00                	push   $0x0
f0104100:	6a 03                	push   $0x3
f0104102:	eb 42                	jmp    f0104146 <_alltraps>

f0104104 <th4>:
    TRAPHANDLER_NOEC(th4, 4)
f0104104:	6a 00                	push   $0x0
f0104106:	6a 04                	push   $0x4
f0104108:	eb 3c                	jmp    f0104146 <_alltraps>

f010410a <th5>:
    TRAPHANDLER_NOEC(th5, 5)
f010410a:	6a 00                	push   $0x0
f010410c:	6a 05                	push   $0x5
f010410e:	eb 36                	jmp    f0104146 <_alltraps>

f0104110 <th6>:
    TRAPHANDLER_NOEC(th6, 6)
f0104110:	6a 00                	push   $0x0
f0104112:	6a 06                	push   $0x6
f0104114:	eb 30                	jmp    f0104146 <_alltraps>

f0104116 <th7>:
    TRAPHANDLER_NOEC(th7, 7)
f0104116:	6a 00                	push   $0x0
f0104118:	6a 07                	push   $0x7
f010411a:	eb 2a                	jmp    f0104146 <_alltraps>

f010411c <th8>:
    TRAPHANDLER(th8, 8)
f010411c:	6a 08                	push   $0x8
f010411e:	eb 26                	jmp    f0104146 <_alltraps>

f0104120 <th9>:
    TRAPHANDLER_NOEC(th9, 9)
f0104120:	6a 00                	push   $0x0
f0104122:	6a 09                	push   $0x9
f0104124:	eb 20                	jmp    f0104146 <_alltraps>

f0104126 <th10>:
    TRAPHANDLER(th10, 10)
f0104126:	6a 0a                	push   $0xa
f0104128:	eb 1c                	jmp    f0104146 <_alltraps>

f010412a <th11>:
    TRAPHANDLER(th11, 11)
f010412a:	6a 0b                	push   $0xb
f010412c:	eb 18                	jmp    f0104146 <_alltraps>

f010412e <th12>:
    TRAPHANDLER(th12, 12)
f010412e:	6a 0c                	push   $0xc
f0104130:	eb 14                	jmp    f0104146 <_alltraps>

f0104132 <th13>:
    TRAPHANDLER(th13, 13)
f0104132:	6a 0d                	push   $0xd
f0104134:	eb 10                	jmp    f0104146 <_alltraps>

f0104136 <th14>:
    TRAPHANDLER(th14, 14)
f0104136:	6a 0e                	push   $0xe
f0104138:	eb 0c                	jmp    f0104146 <_alltraps>

f010413a <th16>:
    TRAPHANDLER_NOEC(th16, 16)
f010413a:	6a 00                	push   $0x0
f010413c:	6a 10                	push   $0x10
f010413e:	eb 06                	jmp    f0104146 <_alltraps>

f0104140 <th_syscall>:
	//创建系统调用的中断
    TRAPHANDLER_NOEC(th_syscall, T_SYSCALL)
f0104140:	6a 00                	push   $0x0
f0104142:	6a 30                	push   $0x30
f0104144:	eb 00                	jmp    f0104146 <_alltraps>

f0104146 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

 //发生中断 将寄存器入栈
 _alltraps:
    pushl %ds
f0104146:	1e                   	push   %ds
    pushl %es
f0104147:	06                   	push   %es
    pushal
f0104148:	60                   	pusha  
    pushl $GD_KD
f0104149:	6a 10                	push   $0x10
    popl %ds
f010414b:	1f                   	pop    %ds
    pushl $GD_KD
f010414c:	6a 10                	push   $0x10
    popl %es
f010414e:	07                   	pop    %es
    pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f010414f:	54                   	push   %esp
    call trap       //调用trap()函数
f0104150:	e8 3b fe ff ff       	call   f0103f90 <trap>
f0104155:	66 90                	xchg   %ax,%ax
f0104157:	66 90                	xchg   %ax,%ax
f0104159:	66 90                	xchg   %ax,%ax
f010415b:	66 90                	xchg   %ax,%ax
f010415d:	66 90                	xchg   %ax,%ax
f010415f:	90                   	nop

f0104160 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104160:	55                   	push   %ebp
f0104161:	89 e5                	mov    %esp,%ebp
f0104163:	83 ec 28             	sub    $0x28,%esp
f0104166:	8b 45 08             	mov    0x8(%ebp),%eax

	//panic("syscall not implemented");

	int32_t ret;
	//调用号->相应函数
	switch (syscallno)
f0104169:	83 f8 01             	cmp    $0x1,%eax
f010416c:	74 5e                	je     f01041cc <syscall+0x6c>
f010416e:	83 f8 01             	cmp    $0x1,%eax
f0104171:	72 12                	jb     f0104185 <syscall+0x25>
f0104173:	83 f8 02             	cmp    $0x2,%eax
f0104176:	74 5b                	je     f01041d3 <syscall+0x73>
f0104178:	83 f8 03             	cmp    $0x3,%eax
f010417b:	74 60                	je     f01041dd <syscall+0x7d>
f010417d:	8d 76 00             	lea    0x0(%esi),%esi
f0104180:	e9 c4 00 00 00       	jmp    f0104249 <syscall+0xe9>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f0104185:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010418c:	00 
f010418d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104190:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104194:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104197:	89 44 24 04          	mov    %eax,0x4(%esp)
f010419b:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01041a0:	89 04 24             	mov    %eax,(%esp)
f01041a3:	e8 de ef ff ff       	call   f0103186 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01041a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041ab:	89 44 24 08          	mov    %eax,0x8(%esp)
f01041af:	8b 45 10             	mov    0x10(%ebp),%eax
f01041b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041b6:	c7 04 24 f0 68 10 f0 	movl   $0xf01068f0,(%esp)
f01041bd:	e8 01 f8 ff ff       	call   f01039c3 <cprintf>
	//调用号->相应函数
	switch (syscallno)
	{
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		ret = 0;
f01041c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01041c7:	e9 82 00 00 00       	jmp    f010424e <syscall+0xee>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01041cc:	e8 04 c3 ff ff       	call   f01004d5 <cons_getc>
		sys_cputs((char *)a1, (size_t)a2);
		ret = 0;
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f01041d1:	eb 7b                	jmp    f010424e <syscall+0xee>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01041d3:	a1 e8 e1 17 f0       	mov    0xf017e1e8,%eax
f01041d8:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f01041db:	eb 71                	jmp    f010424e <syscall+0xee>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01041dd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01041e4:	00 
f01041e5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01041e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041ef:	89 04 24             	mov    %eax,(%esp)
f01041f2:	e8 87 f0 ff ff       	call   f010327e <envid2env>
f01041f7:	85 c0                	test   %eax,%eax
f01041f9:	78 53                	js     f010424e <syscall+0xee>
		return r;
	if (e == curenv)
f01041fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01041fe:	8b 15 e8 e1 17 f0    	mov    0xf017e1e8,%edx
f0104204:	39 d0                	cmp    %edx,%eax
f0104206:	75 15                	jne    f010421d <syscall+0xbd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104208:	8b 40 48             	mov    0x48(%eax),%eax
f010420b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010420f:	c7 04 24 f5 68 10 f0 	movl   $0xf01068f5,(%esp)
f0104216:	e8 a8 f7 ff ff       	call   f01039c3 <cprintf>
f010421b:	eb 1a                	jmp    f0104237 <syscall+0xd7>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010421d:	8b 40 48             	mov    0x48(%eax),%eax
f0104220:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104224:	8b 42 48             	mov    0x48(%edx),%eax
f0104227:	89 44 24 04          	mov    %eax,0x4(%esp)
f010422b:	c7 04 24 10 69 10 f0 	movl   $0xf0106910,(%esp)
f0104232:	e8 8c f7 ff ff       	call   f01039c3 <cprintf>
	env_destroy(e);
f0104237:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010423a:	89 04 24             	mov    %eax,(%esp)
f010423d:	e8 4e f6 ff ff       	call   f0103890 <env_destroy>
	return 0;
f0104242:	b8 00 00 00 00       	mov    $0x0,%eax
f0104247:	eb 05                	jmp    f010424e <syscall+0xee>
		break;
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	default:
		return -E_INVAL;
f0104249:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}

	return ret;
}
f010424e:	c9                   	leave  
f010424f:	c3                   	ret    

f0104250 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104250:	55                   	push   %ebp
f0104251:	89 e5                	mov    %esp,%ebp
f0104253:	57                   	push   %edi
f0104254:	56                   	push   %esi
f0104255:	53                   	push   %ebx
f0104256:	83 ec 14             	sub    $0x14,%esp
f0104259:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010425c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010425f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104262:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104265:	8b 1a                	mov    (%edx),%ebx
f0104267:	8b 01                	mov    (%ecx),%eax
f0104269:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010426c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104273:	e9 88 00 00 00       	jmp    f0104300 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104278:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010427b:	01 d8                	add    %ebx,%eax
f010427d:	89 c7                	mov    %eax,%edi
f010427f:	c1 ef 1f             	shr    $0x1f,%edi
f0104282:	01 c7                	add    %eax,%edi
f0104284:	d1 ff                	sar    %edi
f0104286:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104289:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010428c:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010428f:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104291:	eb 03                	jmp    f0104296 <stab_binsearch+0x46>
			m--;
f0104293:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104296:	39 c3                	cmp    %eax,%ebx
f0104298:	7f 1f                	jg     f01042b9 <stab_binsearch+0x69>
f010429a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010429e:	83 ea 0c             	sub    $0xc,%edx
f01042a1:	39 f1                	cmp    %esi,%ecx
f01042a3:	75 ee                	jne    f0104293 <stab_binsearch+0x43>
f01042a5:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01042a8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01042ab:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01042ae:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01042b2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01042b5:	76 18                	jbe    f01042cf <stab_binsearch+0x7f>
f01042b7:	eb 05                	jmp    f01042be <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01042b9:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01042bc:	eb 42                	jmp    f0104300 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01042be:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01042c1:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01042c3:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01042c6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01042cd:	eb 31                	jmp    f0104300 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01042cf:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01042d2:	73 17                	jae    f01042eb <stab_binsearch+0x9b>
			*region_right = m - 1;
f01042d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01042d7:	83 e8 01             	sub    $0x1,%eax
f01042da:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01042dd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01042e0:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01042e2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01042e9:	eb 15                	jmp    f0104300 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01042eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01042ee:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01042f1:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01042f3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01042f7:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01042f9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104300:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104303:	0f 8e 6f ff ff ff    	jle    f0104278 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104309:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010430d:	75 0f                	jne    f010431e <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010430f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104312:	8b 00                	mov    (%eax),%eax
f0104314:	83 e8 01             	sub    $0x1,%eax
f0104317:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010431a:	89 07                	mov    %eax,(%edi)
f010431c:	eb 2c                	jmp    f010434a <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010431e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104321:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104323:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104326:	8b 0f                	mov    (%edi),%ecx
f0104328:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010432b:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010432e:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104331:	eb 03                	jmp    f0104336 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104333:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104336:	39 c8                	cmp    %ecx,%eax
f0104338:	7e 0b                	jle    f0104345 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010433a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010433e:	83 ea 0c             	sub    $0xc,%edx
f0104341:	39 f3                	cmp    %esi,%ebx
f0104343:	75 ee                	jne    f0104333 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104345:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104348:	89 07                	mov    %eax,(%edi)
	}
}
f010434a:	83 c4 14             	add    $0x14,%esp
f010434d:	5b                   	pop    %ebx
f010434e:	5e                   	pop    %esi
f010434f:	5f                   	pop    %edi
f0104350:	5d                   	pop    %ebp
f0104351:	c3                   	ret    

f0104352 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104352:	55                   	push   %ebp
f0104353:	89 e5                	mov    %esp,%ebp
f0104355:	57                   	push   %edi
f0104356:	56                   	push   %esi
f0104357:	53                   	push   %ebx
f0104358:	83 ec 4c             	sub    $0x4c,%esp
f010435b:	8b 75 08             	mov    0x8(%ebp),%esi
f010435e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104361:	c7 03 28 69 10 f0    	movl   $0xf0106928,(%ebx)
	info->eip_line = 0;
f0104367:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010436e:	c7 43 08 28 69 10 f0 	movl   $0xf0106928,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104375:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010437c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010437f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104386:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010438c:	77 21                	ja     f01043af <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010438e:	a1 00 00 20 00       	mov    0x200000,%eax
f0104393:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104396:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010439b:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01043a1:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01043a4:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01043aa:	89 7d bc             	mov    %edi,-0x44(%ebp)
f01043ad:	eb 1a                	jmp    f01043c9 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01043af:	c7 45 bc 9e 16 11 f0 	movl   $0xf011169e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01043b6:	c7 45 c0 9d eb 10 f0 	movl   $0xf010eb9d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01043bd:	b8 9c eb 10 f0       	mov    $0xf010eb9c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01043c2:	c7 45 c4 50 6b 10 f0 	movl   $0xf0106b50,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01043c9:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01043cc:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f01043cf:	0f 83 94 01 00 00    	jae    f0104569 <debuginfo_eip+0x217>
f01043d5:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01043d9:	0f 85 91 01 00 00    	jne    f0104570 <debuginfo_eip+0x21e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01043df:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01043e6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01043e9:	29 f8                	sub    %edi,%eax
f01043eb:	c1 f8 02             	sar    $0x2,%eax
f01043ee:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01043f4:	83 e8 01             	sub    $0x1,%eax
f01043f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
        

        stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f01043fa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043fe:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104405:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104408:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010440b:	89 f8                	mov    %edi,%eax
f010440d:	e8 3e fe ff ff       	call   f0104250 <stab_binsearch>
	if(lline>rline)
f0104412:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104415:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104418:	0f 8f 59 01 00 00    	jg     f0104577 <debuginfo_eip+0x225>
	{
		return -1;
	}
	else
	{
	  info->eip_line=stabs[lline].n_desc;
f010441e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104421:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f0104426:	89 43 04             	mov    %eax,0x4(%ebx)
	}
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104429:	89 74 24 04          	mov    %esi,0x4(%esp)
f010442d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104434:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104437:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010443a:	89 f8                	mov    %edi,%eax
f010443c:	e8 0f fe ff ff       	call   f0104250 <stab_binsearch>
	if (lfile == 0)
f0104441:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104444:	85 c0                	test   %eax,%eax
f0104446:	0f 84 32 01 00 00    	je     f010457e <debuginfo_eip+0x22c>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010444c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010444f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104452:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104455:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104459:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104460:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104463:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104466:	89 f8                	mov    %edi,%eax
f0104468:	e8 e3 fd ff ff       	call   f0104250 <stab_binsearch>

	if (lfun <= rfun) {
f010446d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104470:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0104473:	39 f8                	cmp    %edi,%eax
f0104475:	7f 29                	jg     f01044a0 <debuginfo_eip+0x14e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104477:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010447a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010447d:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104480:	8b 0a                	mov    (%edx),%ecx
f0104482:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104485:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104488:	39 f1                	cmp    %esi,%ecx
f010448a:	73 06                	jae    f0104492 <debuginfo_eip+0x140>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010448c:	03 4d c0             	add    -0x40(%ebp),%ecx
f010448f:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104492:	8b 52 08             	mov    0x8(%edx),%edx
f0104495:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
		// Search within the function definition for the line number.
		lline = lfun;
f0104498:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010449b:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010449e:	eb 0f                	jmp    f01044af <debuginfo_eip+0x15d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01044a0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01044a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044a6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01044a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01044af:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01044b6:	00 
f01044b7:	8b 43 08             	mov    0x8(%ebx),%eax
f01044ba:	89 04 24             	mov    %eax,(%esp)
f01044bd:	e8 e9 08 00 00       	call   f0104dab <strfind>
f01044c2:	2b 43 08             	sub    0x8(%ebx),%eax
f01044c5:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01044c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044cb:	89 c6                	mov    %eax,%esi
f01044cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01044d0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01044d3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01044d6:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01044d9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01044dc:	eb 06                	jmp    f01044e4 <debuginfo_eip+0x192>
f01044de:	83 e8 01             	sub    $0x1,%eax
f01044e1:	83 ea 0c             	sub    $0xc,%edx
f01044e4:	89 c7                	mov    %eax,%edi
f01044e6:	39 c6                	cmp    %eax,%esi
f01044e8:	7f 3c                	jg     f0104526 <debuginfo_eip+0x1d4>
	       && stabs[lline].n_type != N_SOL
f01044ea:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01044ee:	80 f9 84             	cmp    $0x84,%cl
f01044f1:	75 08                	jne    f01044fb <debuginfo_eip+0x1a9>
f01044f3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01044f9:	eb 11                	jmp    f010450c <debuginfo_eip+0x1ba>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044fb:	80 f9 64             	cmp    $0x64,%cl
f01044fe:	75 de                	jne    f01044de <debuginfo_eip+0x18c>
f0104500:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104504:	74 d8                	je     f01044de <debuginfo_eip+0x18c>
f0104506:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104509:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010450c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010450f:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104512:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0104515:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104518:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010451b:	39 d0                	cmp    %edx,%eax
f010451d:	73 0a                	jae    f0104529 <debuginfo_eip+0x1d7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010451f:	03 45 c0             	add    -0x40(%ebp),%eax
f0104522:	89 03                	mov    %eax,(%ebx)
f0104524:	eb 03                	jmp    f0104529 <debuginfo_eip+0x1d7>
f0104526:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104529:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010452c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010452f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104534:	39 f2                	cmp    %esi,%edx
f0104536:	7d 52                	jge    f010458a <debuginfo_eip+0x238>
		for (lline = lfun + 1;
f0104538:	83 c2 01             	add    $0x1,%edx
f010453b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010453e:	89 d0                	mov    %edx,%eax
f0104540:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104543:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104546:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104549:	eb 04                	jmp    f010454f <debuginfo_eip+0x1fd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010454b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010454f:	39 c6                	cmp    %eax,%esi
f0104551:	7e 32                	jle    f0104585 <debuginfo_eip+0x233>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104553:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104557:	83 c0 01             	add    $0x1,%eax
f010455a:	83 c2 0c             	add    $0xc,%edx
f010455d:	80 f9 a0             	cmp    $0xa0,%cl
f0104560:	74 e9                	je     f010454b <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104562:	b8 00 00 00 00       	mov    $0x0,%eax
f0104567:	eb 21                	jmp    f010458a <debuginfo_eip+0x238>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104569:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010456e:	eb 1a                	jmp    f010458a <debuginfo_eip+0x238>
f0104570:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104575:	eb 13                	jmp    f010458a <debuginfo_eip+0x238>
        

        stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
	if(lline>rline)
	{
		return -1;
f0104577:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010457c:	eb 0c                	jmp    f010458a <debuginfo_eip+0x238>
	{
	  info->eip_line=stabs[lline].n_desc;
	}
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010457e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104583:	eb 05                	jmp    f010458a <debuginfo_eip+0x238>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104585:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010458a:	83 c4 4c             	add    $0x4c,%esp
f010458d:	5b                   	pop    %ebx
f010458e:	5e                   	pop    %esi
f010458f:	5f                   	pop    %edi
f0104590:	5d                   	pop    %ebp
f0104591:	c3                   	ret    
f0104592:	66 90                	xchg   %ax,%ax
f0104594:	66 90                	xchg   %ax,%ax
f0104596:	66 90                	xchg   %ax,%ax
f0104598:	66 90                	xchg   %ax,%ax
f010459a:	66 90                	xchg   %ax,%ax
f010459c:	66 90                	xchg   %ax,%ax
f010459e:	66 90                	xchg   %ax,%ax

f01045a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01045a0:	55                   	push   %ebp
f01045a1:	89 e5                	mov    %esp,%ebp
f01045a3:	57                   	push   %edi
f01045a4:	56                   	push   %esi
f01045a5:	53                   	push   %ebx
f01045a6:	83 ec 3c             	sub    $0x3c,%esp
f01045a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01045ac:	89 d7                	mov    %edx,%edi
f01045ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01045b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045b7:	89 c3                	mov    %eax,%ebx
f01045b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01045bc:	8b 45 10             	mov    0x10(%ebp),%eax
f01045bf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01045c2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01045c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01045ca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01045cd:	39 d9                	cmp    %ebx,%ecx
f01045cf:	72 05                	jb     f01045d6 <printnum+0x36>
f01045d1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01045d4:	77 69                	ja     f010463f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01045d6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01045d9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01045dd:	83 ee 01             	sub    $0x1,%esi
f01045e0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01045e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045e8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045ec:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01045f0:	89 c3                	mov    %eax,%ebx
f01045f2:	89 d6                	mov    %edx,%esi
f01045f4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01045f7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01045fa:	89 54 24 08          	mov    %edx,0x8(%esp)
f01045fe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104602:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104605:	89 04 24             	mov    %eax,(%esp)
f0104608:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010460b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010460f:	e8 bc 09 00 00       	call   f0104fd0 <__udivdi3>
f0104614:	89 d9                	mov    %ebx,%ecx
f0104616:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010461a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010461e:	89 04 24             	mov    %eax,(%esp)
f0104621:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104625:	89 fa                	mov    %edi,%edx
f0104627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010462a:	e8 71 ff ff ff       	call   f01045a0 <printnum>
f010462f:	eb 1b                	jmp    f010464c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104631:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104635:	8b 45 18             	mov    0x18(%ebp),%eax
f0104638:	89 04 24             	mov    %eax,(%esp)
f010463b:	ff d3                	call   *%ebx
f010463d:	eb 03                	jmp    f0104642 <printnum+0xa2>
f010463f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104642:	83 ee 01             	sub    $0x1,%esi
f0104645:	85 f6                	test   %esi,%esi
f0104647:	7f e8                	jg     f0104631 <printnum+0x91>
f0104649:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010464c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104650:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104654:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104657:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010465a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010465e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104662:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104665:	89 04 24             	mov    %eax,(%esp)
f0104668:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010466b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010466f:	e8 8c 0a 00 00       	call   f0105100 <__umoddi3>
f0104674:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104678:	0f be 80 32 69 10 f0 	movsbl -0xfef96ce(%eax),%eax
f010467f:	89 04 24             	mov    %eax,(%esp)
f0104682:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104685:	ff d0                	call   *%eax
}
f0104687:	83 c4 3c             	add    $0x3c,%esp
f010468a:	5b                   	pop    %ebx
f010468b:	5e                   	pop    %esi
f010468c:	5f                   	pop    %edi
f010468d:	5d                   	pop    %ebp
f010468e:	c3                   	ret    

f010468f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010468f:	55                   	push   %ebp
f0104690:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104692:	83 fa 01             	cmp    $0x1,%edx
f0104695:	7e 0e                	jle    f01046a5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104697:	8b 10                	mov    (%eax),%edx
f0104699:	8d 4a 08             	lea    0x8(%edx),%ecx
f010469c:	89 08                	mov    %ecx,(%eax)
f010469e:	8b 02                	mov    (%edx),%eax
f01046a0:	8b 52 04             	mov    0x4(%edx),%edx
f01046a3:	eb 22                	jmp    f01046c7 <getuint+0x38>
	else if (lflag)
f01046a5:	85 d2                	test   %edx,%edx
f01046a7:	74 10                	je     f01046b9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01046a9:	8b 10                	mov    (%eax),%edx
f01046ab:	8d 4a 04             	lea    0x4(%edx),%ecx
f01046ae:	89 08                	mov    %ecx,(%eax)
f01046b0:	8b 02                	mov    (%edx),%eax
f01046b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01046b7:	eb 0e                	jmp    f01046c7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01046b9:	8b 10                	mov    (%eax),%edx
f01046bb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01046be:	89 08                	mov    %ecx,(%eax)
f01046c0:	8b 02                	mov    (%edx),%eax
f01046c2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01046c7:	5d                   	pop    %ebp
f01046c8:	c3                   	ret    

f01046c9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01046c9:	55                   	push   %ebp
f01046ca:	89 e5                	mov    %esp,%ebp
f01046cc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01046cf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01046d3:	8b 10                	mov    (%eax),%edx
f01046d5:	3b 50 04             	cmp    0x4(%eax),%edx
f01046d8:	73 0a                	jae    f01046e4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01046da:	8d 4a 01             	lea    0x1(%edx),%ecx
f01046dd:	89 08                	mov    %ecx,(%eax)
f01046df:	8b 45 08             	mov    0x8(%ebp),%eax
f01046e2:	88 02                	mov    %al,(%edx)
}
f01046e4:	5d                   	pop    %ebp
f01046e5:	c3                   	ret    

f01046e6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01046e6:	55                   	push   %ebp
f01046e7:	89 e5                	mov    %esp,%ebp
f01046e9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01046ec:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01046ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046f3:	8b 45 10             	mov    0x10(%ebp),%eax
f01046f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104701:	8b 45 08             	mov    0x8(%ebp),%eax
f0104704:	89 04 24             	mov    %eax,(%esp)
f0104707:	e8 02 00 00 00       	call   f010470e <vprintfmt>
	va_end(ap);
}
f010470c:	c9                   	leave  
f010470d:	c3                   	ret    

f010470e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010470e:	55                   	push   %ebp
f010470f:	89 e5                	mov    %esp,%ebp
f0104711:	57                   	push   %edi
f0104712:	56                   	push   %esi
f0104713:	53                   	push   %ebx
f0104714:	83 ec 3c             	sub    $0x3c,%esp
f0104717:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010471a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010471d:	eb 14                	jmp    f0104733 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010471f:	85 c0                	test   %eax,%eax
f0104721:	0f 84 b3 03 00 00    	je     f0104ada <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104727:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010472b:	89 04 24             	mov    %eax,(%esp)
f010472e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104731:	89 f3                	mov    %esi,%ebx
f0104733:	8d 73 01             	lea    0x1(%ebx),%esi
f0104736:	0f b6 03             	movzbl (%ebx),%eax
f0104739:	83 f8 25             	cmp    $0x25,%eax
f010473c:	75 e1                	jne    f010471f <vprintfmt+0x11>
f010473e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104742:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104749:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104750:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104757:	ba 00 00 00 00       	mov    $0x0,%edx
f010475c:	eb 1d                	jmp    f010477b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010475e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104760:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104764:	eb 15                	jmp    f010477b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104766:	89 de                	mov    %ebx,%esi
			goto reswitch;


		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104768:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010476c:	eb 0d                	jmp    f010477b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010476e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104771:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104774:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010477b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010477e:	0f b6 0e             	movzbl (%esi),%ecx
f0104781:	0f b6 c1             	movzbl %cl,%eax
f0104784:	83 e9 23             	sub    $0x23,%ecx
f0104787:	80 f9 55             	cmp    $0x55,%cl
f010478a:	0f 87 2a 03 00 00    	ja     f0104aba <vprintfmt+0x3ac>
f0104790:	0f b6 c9             	movzbl %cl,%ecx
f0104793:	ff 24 8d c0 69 10 f0 	jmp    *-0xfef9640(,%ecx,4)
f010479a:	89 de                	mov    %ebx,%esi
f010479c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01047a1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01047a4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01047a8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01047ab:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01047ae:	83 fb 09             	cmp    $0x9,%ebx
f01047b1:	77 36                	ja     f01047e9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01047b3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01047b6:	eb e9                	jmp    f01047a1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01047b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01047bb:	8d 48 04             	lea    0x4(%eax),%ecx
f01047be:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01047c1:	8b 00                	mov    (%eax),%eax
f01047c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047c6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01047c8:	eb 22                	jmp    f01047ec <vprintfmt+0xde>
f01047ca:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01047cd:	85 c9                	test   %ecx,%ecx
f01047cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01047d4:	0f 49 c1             	cmovns %ecx,%eax
f01047d7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047da:	89 de                	mov    %ebx,%esi
f01047dc:	eb 9d                	jmp    f010477b <vprintfmt+0x6d>
f01047de:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01047e0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01047e7:	eb 92                	jmp    f010477b <vprintfmt+0x6d>
f01047e9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01047ec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01047f0:	79 89                	jns    f010477b <vprintfmt+0x6d>
f01047f2:	e9 77 ff ff ff       	jmp    f010476e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01047f7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047fa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01047fc:	e9 7a ff ff ff       	jmp    f010477b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104801:	8b 45 14             	mov    0x14(%ebp),%eax
f0104804:	8d 50 04             	lea    0x4(%eax),%edx
f0104807:	89 55 14             	mov    %edx,0x14(%ebp)
f010480a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010480e:	8b 00                	mov    (%eax),%eax
f0104810:	89 04 24             	mov    %eax,(%esp)
f0104813:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104816:	e9 18 ff ff ff       	jmp    f0104733 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010481b:	8b 45 14             	mov    0x14(%ebp),%eax
f010481e:	8d 50 04             	lea    0x4(%eax),%edx
f0104821:	89 55 14             	mov    %edx,0x14(%ebp)
f0104824:	8b 00                	mov    (%eax),%eax
f0104826:	99                   	cltd   
f0104827:	31 d0                	xor    %edx,%eax
f0104829:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010482b:	83 f8 07             	cmp    $0x7,%eax
f010482e:	7f 0b                	jg     f010483b <vprintfmt+0x12d>
f0104830:	8b 14 85 20 6b 10 f0 	mov    -0xfef94e0(,%eax,4),%edx
f0104837:	85 d2                	test   %edx,%edx
f0104839:	75 20                	jne    f010485b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010483b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010483f:	c7 44 24 08 4a 69 10 	movl   $0xf010694a,0x8(%esp)
f0104846:	f0 
f0104847:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010484b:	8b 45 08             	mov    0x8(%ebp),%eax
f010484e:	89 04 24             	mov    %eax,(%esp)
f0104851:	e8 90 fe ff ff       	call   f01046e6 <printfmt>
f0104856:	e9 d8 fe ff ff       	jmp    f0104733 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010485b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010485f:	c7 44 24 08 f8 58 10 	movl   $0xf01058f8,0x8(%esp)
f0104866:	f0 
f0104867:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010486b:	8b 45 08             	mov    0x8(%ebp),%eax
f010486e:	89 04 24             	mov    %eax,(%esp)
f0104871:	e8 70 fe ff ff       	call   f01046e6 <printfmt>
f0104876:	e9 b8 fe ff ff       	jmp    f0104733 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010487b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010487e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104881:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104884:	8b 45 14             	mov    0x14(%ebp),%eax
f0104887:	8d 50 04             	lea    0x4(%eax),%edx
f010488a:	89 55 14             	mov    %edx,0x14(%ebp)
f010488d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010488f:	85 f6                	test   %esi,%esi
f0104891:	b8 43 69 10 f0       	mov    $0xf0106943,%eax
f0104896:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0104899:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010489d:	0f 84 97 00 00 00    	je     f010493a <vprintfmt+0x22c>
f01048a3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01048a7:	0f 8e 9b 00 00 00    	jle    f0104948 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01048ad:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01048b1:	89 34 24             	mov    %esi,(%esp)
f01048b4:	e8 9f 03 00 00       	call   f0104c58 <strnlen>
f01048b9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01048bc:	29 c2                	sub    %eax,%edx
f01048be:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01048c1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01048c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01048c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01048cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01048ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01048d1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01048d3:	eb 0f                	jmp    f01048e4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01048d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01048dc:	89 04 24             	mov    %eax,(%esp)
f01048df:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01048e1:	83 eb 01             	sub    $0x1,%ebx
f01048e4:	85 db                	test   %ebx,%ebx
f01048e6:	7f ed                	jg     f01048d5 <vprintfmt+0x1c7>
f01048e8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01048eb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01048ee:	85 d2                	test   %edx,%edx
f01048f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01048f5:	0f 49 c2             	cmovns %edx,%eax
f01048f8:	29 c2                	sub    %eax,%edx
f01048fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01048fd:	89 d7                	mov    %edx,%edi
f01048ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104902:	eb 50                	jmp    f0104954 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104904:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104908:	74 1e                	je     f0104928 <vprintfmt+0x21a>
f010490a:	0f be d2             	movsbl %dl,%edx
f010490d:	83 ea 20             	sub    $0x20,%edx
f0104910:	83 fa 5e             	cmp    $0x5e,%edx
f0104913:	76 13                	jbe    f0104928 <vprintfmt+0x21a>
					putch('?', putdat);
f0104915:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104918:	89 44 24 04          	mov    %eax,0x4(%esp)
f010491c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104923:	ff 55 08             	call   *0x8(%ebp)
f0104926:	eb 0d                	jmp    f0104935 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104928:	8b 55 0c             	mov    0xc(%ebp),%edx
f010492b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010492f:	89 04 24             	mov    %eax,(%esp)
f0104932:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104935:	83 ef 01             	sub    $0x1,%edi
f0104938:	eb 1a                	jmp    f0104954 <vprintfmt+0x246>
f010493a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010493d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104940:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104943:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104946:	eb 0c                	jmp    f0104954 <vprintfmt+0x246>
f0104948:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010494b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010494e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104951:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104954:	83 c6 01             	add    $0x1,%esi
f0104957:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010495b:	0f be c2             	movsbl %dl,%eax
f010495e:	85 c0                	test   %eax,%eax
f0104960:	74 27                	je     f0104989 <vprintfmt+0x27b>
f0104962:	85 db                	test   %ebx,%ebx
f0104964:	78 9e                	js     f0104904 <vprintfmt+0x1f6>
f0104966:	83 eb 01             	sub    $0x1,%ebx
f0104969:	79 99                	jns    f0104904 <vprintfmt+0x1f6>
f010496b:	89 f8                	mov    %edi,%eax
f010496d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104970:	8b 75 08             	mov    0x8(%ebp),%esi
f0104973:	89 c3                	mov    %eax,%ebx
f0104975:	eb 1a                	jmp    f0104991 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104977:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010497b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104982:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104984:	83 eb 01             	sub    $0x1,%ebx
f0104987:	eb 08                	jmp    f0104991 <vprintfmt+0x283>
f0104989:	89 fb                	mov    %edi,%ebx
f010498b:	8b 75 08             	mov    0x8(%ebp),%esi
f010498e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104991:	85 db                	test   %ebx,%ebx
f0104993:	7f e2                	jg     f0104977 <vprintfmt+0x269>
f0104995:	89 75 08             	mov    %esi,0x8(%ebp)
f0104998:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010499b:	e9 93 fd ff ff       	jmp    f0104733 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01049a0:	83 fa 01             	cmp    $0x1,%edx
f01049a3:	7e 16                	jle    f01049bb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01049a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01049a8:	8d 50 08             	lea    0x8(%eax),%edx
f01049ab:	89 55 14             	mov    %edx,0x14(%ebp)
f01049ae:	8b 50 04             	mov    0x4(%eax),%edx
f01049b1:	8b 00                	mov    (%eax),%eax
f01049b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01049b6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01049b9:	eb 32                	jmp    f01049ed <vprintfmt+0x2df>
	else if (lflag)
f01049bb:	85 d2                	test   %edx,%edx
f01049bd:	74 18                	je     f01049d7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01049bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01049c2:	8d 50 04             	lea    0x4(%eax),%edx
f01049c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01049c8:	8b 30                	mov    (%eax),%esi
f01049ca:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01049cd:	89 f0                	mov    %esi,%eax
f01049cf:	c1 f8 1f             	sar    $0x1f,%eax
f01049d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01049d5:	eb 16                	jmp    f01049ed <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01049d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01049da:	8d 50 04             	lea    0x4(%eax),%edx
f01049dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01049e0:	8b 30                	mov    (%eax),%esi
f01049e2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01049e5:	89 f0                	mov    %esi,%eax
f01049e7:	c1 f8 1f             	sar    $0x1f,%eax
f01049ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01049ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01049f3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01049f8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01049fc:	0f 89 80 00 00 00    	jns    f0104a82 <vprintfmt+0x374>
				putch('-', putdat);
f0104a02:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a06:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104a0d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104a10:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a13:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104a16:	f7 d8                	neg    %eax
f0104a18:	83 d2 00             	adc    $0x0,%edx
f0104a1b:	f7 da                	neg    %edx
			}
			base = 10;
f0104a1d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104a22:	eb 5e                	jmp    f0104a82 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104a24:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a27:	e8 63 fc ff ff       	call   f010468f <getuint>
			base = 10;
f0104a2c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104a31:	eb 4f                	jmp    f0104a82 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
f0104a33:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a36:	e8 54 fc ff ff       	call   f010468f <getuint>
			base=8;
f0104a3b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104a40:	eb 40                	jmp    f0104a82 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0104a42:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a46:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104a4d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104a50:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a54:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104a5b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104a5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a61:	8d 50 04             	lea    0x4(%eax),%edx
f0104a64:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104a67:	8b 00                	mov    (%eax),%eax
f0104a69:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104a6e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104a73:	eb 0d                	jmp    f0104a82 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104a75:	8d 45 14             	lea    0x14(%ebp),%eax
f0104a78:	e8 12 fc ff ff       	call   f010468f <getuint>
			base = 16;
f0104a7d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104a82:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104a86:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104a8a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104a8d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104a91:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a95:	89 04 24             	mov    %eax,(%esp)
f0104a98:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a9c:	89 fa                	mov    %edi,%edx
f0104a9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aa1:	e8 fa fa ff ff       	call   f01045a0 <printnum>
			break;
f0104aa6:	e9 88 fc ff ff       	jmp    f0104733 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104aab:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104aaf:	89 04 24             	mov    %eax,(%esp)
f0104ab2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104ab5:	e9 79 fc ff ff       	jmp    f0104733 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104aba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104abe:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104ac5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104ac8:	89 f3                	mov    %esi,%ebx
f0104aca:	eb 03                	jmp    f0104acf <vprintfmt+0x3c1>
f0104acc:	83 eb 01             	sub    $0x1,%ebx
f0104acf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104ad3:	75 f7                	jne    f0104acc <vprintfmt+0x3be>
f0104ad5:	e9 59 fc ff ff       	jmp    f0104733 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104ada:	83 c4 3c             	add    $0x3c,%esp
f0104add:	5b                   	pop    %ebx
f0104ade:	5e                   	pop    %esi
f0104adf:	5f                   	pop    %edi
f0104ae0:	5d                   	pop    %ebp
f0104ae1:	c3                   	ret    

f0104ae2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104ae2:	55                   	push   %ebp
f0104ae3:	89 e5                	mov    %esp,%ebp
f0104ae5:	83 ec 28             	sub    $0x28,%esp
f0104ae8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aeb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104aee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104af1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104af5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104af8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104aff:	85 c0                	test   %eax,%eax
f0104b01:	74 30                	je     f0104b33 <vsnprintf+0x51>
f0104b03:	85 d2                	test   %edx,%edx
f0104b05:	7e 2c                	jle    f0104b33 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104b07:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b0e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b15:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104b18:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b1c:	c7 04 24 c9 46 10 f0 	movl   $0xf01046c9,(%esp)
f0104b23:	e8 e6 fb ff ff       	call   f010470e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104b28:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104b2b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b31:	eb 05                	jmp    f0104b38 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104b33:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104b38:	c9                   	leave  
f0104b39:	c3                   	ret    

f0104b3a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104b3a:	55                   	push   %ebp
f0104b3b:	89 e5                	mov    %esp,%ebp
f0104b3d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104b40:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104b43:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b47:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b4a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b55:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b58:	89 04 24             	mov    %eax,(%esp)
f0104b5b:	e8 82 ff ff ff       	call   f0104ae2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104b60:	c9                   	leave  
f0104b61:	c3                   	ret    
f0104b62:	66 90                	xchg   %ax,%ax
f0104b64:	66 90                	xchg   %ax,%ax
f0104b66:	66 90                	xchg   %ax,%ax
f0104b68:	66 90                	xchg   %ax,%ax
f0104b6a:	66 90                	xchg   %ax,%ax
f0104b6c:	66 90                	xchg   %ax,%ax
f0104b6e:	66 90                	xchg   %ax,%ax

f0104b70 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104b70:	55                   	push   %ebp
f0104b71:	89 e5                	mov    %esp,%ebp
f0104b73:	57                   	push   %edi
f0104b74:	56                   	push   %esi
f0104b75:	53                   	push   %ebx
f0104b76:	83 ec 1c             	sub    $0x1c,%esp
f0104b79:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104b7c:	85 c0                	test   %eax,%eax
f0104b7e:	74 10                	je     f0104b90 <readline+0x20>
		cprintf("%s", prompt);
f0104b80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b84:	c7 04 24 f8 58 10 f0 	movl   $0xf01058f8,(%esp)
f0104b8b:	e8 33 ee ff ff       	call   f01039c3 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104b90:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104b97:	e8 96 ba ff ff       	call   f0100632 <iscons>
f0104b9c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104b9e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104ba3:	e8 79 ba ff ff       	call   f0100621 <getchar>
f0104ba8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104baa:	85 c0                	test   %eax,%eax
f0104bac:	79 17                	jns    f0104bc5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104bae:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bb2:	c7 04 24 40 6b 10 f0 	movl   $0xf0106b40,(%esp)
f0104bb9:	e8 05 ee ff ff       	call   f01039c3 <cprintf>
			return NULL;
f0104bbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bc3:	eb 6d                	jmp    f0104c32 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104bc5:	83 f8 7f             	cmp    $0x7f,%eax
f0104bc8:	74 05                	je     f0104bcf <readline+0x5f>
f0104bca:	83 f8 08             	cmp    $0x8,%eax
f0104bcd:	75 19                	jne    f0104be8 <readline+0x78>
f0104bcf:	85 f6                	test   %esi,%esi
f0104bd1:	7e 15                	jle    f0104be8 <readline+0x78>
			if (echoing)
f0104bd3:	85 ff                	test   %edi,%edi
f0104bd5:	74 0c                	je     f0104be3 <readline+0x73>
				cputchar('\b');
f0104bd7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104bde:	e8 2e ba ff ff       	call   f0100611 <cputchar>
			i--;
f0104be3:	83 ee 01             	sub    $0x1,%esi
f0104be6:	eb bb                	jmp    f0104ba3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104be8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104bee:	7f 1c                	jg     f0104c0c <readline+0x9c>
f0104bf0:	83 fb 1f             	cmp    $0x1f,%ebx
f0104bf3:	7e 17                	jle    f0104c0c <readline+0x9c>
			if (echoing)
f0104bf5:	85 ff                	test   %edi,%edi
f0104bf7:	74 08                	je     f0104c01 <readline+0x91>
				cputchar(c);
f0104bf9:	89 1c 24             	mov    %ebx,(%esp)
f0104bfc:	e8 10 ba ff ff       	call   f0100611 <cputchar>
			buf[i++] = c;
f0104c01:	88 9e a0 ea 17 f0    	mov    %bl,-0xfe81560(%esi)
f0104c07:	8d 76 01             	lea    0x1(%esi),%esi
f0104c0a:	eb 97                	jmp    f0104ba3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104c0c:	83 fb 0d             	cmp    $0xd,%ebx
f0104c0f:	74 05                	je     f0104c16 <readline+0xa6>
f0104c11:	83 fb 0a             	cmp    $0xa,%ebx
f0104c14:	75 8d                	jne    f0104ba3 <readline+0x33>
			if (echoing)
f0104c16:	85 ff                	test   %edi,%edi
f0104c18:	74 0c                	je     f0104c26 <readline+0xb6>
				cputchar('\n');
f0104c1a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104c21:	e8 eb b9 ff ff       	call   f0100611 <cputchar>
			buf[i] = 0;
f0104c26:	c6 86 a0 ea 17 f0 00 	movb   $0x0,-0xfe81560(%esi)
			return buf;
f0104c2d:	b8 a0 ea 17 f0       	mov    $0xf017eaa0,%eax
		}
	}
}
f0104c32:	83 c4 1c             	add    $0x1c,%esp
f0104c35:	5b                   	pop    %ebx
f0104c36:	5e                   	pop    %esi
f0104c37:	5f                   	pop    %edi
f0104c38:	5d                   	pop    %ebp
f0104c39:	c3                   	ret    
f0104c3a:	66 90                	xchg   %ax,%ax
f0104c3c:	66 90                	xchg   %ax,%ax
f0104c3e:	66 90                	xchg   %ax,%ax

f0104c40 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104c40:	55                   	push   %ebp
f0104c41:	89 e5                	mov    %esp,%ebp
f0104c43:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104c46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c4b:	eb 03                	jmp    f0104c50 <strlen+0x10>
		n++;
f0104c4d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104c50:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104c54:	75 f7                	jne    f0104c4d <strlen+0xd>
		n++;
	return n;
}
f0104c56:	5d                   	pop    %ebp
f0104c57:	c3                   	ret    

f0104c58 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104c58:	55                   	push   %ebp
f0104c59:	89 e5                	mov    %esp,%ebp
f0104c5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c5e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104c61:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c66:	eb 03                	jmp    f0104c6b <strnlen+0x13>
		n++;
f0104c68:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104c6b:	39 d0                	cmp    %edx,%eax
f0104c6d:	74 06                	je     f0104c75 <strnlen+0x1d>
f0104c6f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104c73:	75 f3                	jne    f0104c68 <strnlen+0x10>
		n++;
	return n;
}
f0104c75:	5d                   	pop    %ebp
f0104c76:	c3                   	ret    

f0104c77 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104c77:	55                   	push   %ebp
f0104c78:	89 e5                	mov    %esp,%ebp
f0104c7a:	53                   	push   %ebx
f0104c7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c7e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104c81:	89 c2                	mov    %eax,%edx
f0104c83:	83 c2 01             	add    $0x1,%edx
f0104c86:	83 c1 01             	add    $0x1,%ecx
f0104c89:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104c8d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104c90:	84 db                	test   %bl,%bl
f0104c92:	75 ef                	jne    f0104c83 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104c94:	5b                   	pop    %ebx
f0104c95:	5d                   	pop    %ebp
f0104c96:	c3                   	ret    

f0104c97 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104c97:	55                   	push   %ebp
f0104c98:	89 e5                	mov    %esp,%ebp
f0104c9a:	53                   	push   %ebx
f0104c9b:	83 ec 08             	sub    $0x8,%esp
f0104c9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ca1:	89 1c 24             	mov    %ebx,(%esp)
f0104ca4:	e8 97 ff ff ff       	call   f0104c40 <strlen>
	strcpy(dst + len, src);
f0104ca9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cac:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104cb0:	01 d8                	add    %ebx,%eax
f0104cb2:	89 04 24             	mov    %eax,(%esp)
f0104cb5:	e8 bd ff ff ff       	call   f0104c77 <strcpy>
	return dst;
}
f0104cba:	89 d8                	mov    %ebx,%eax
f0104cbc:	83 c4 08             	add    $0x8,%esp
f0104cbf:	5b                   	pop    %ebx
f0104cc0:	5d                   	pop    %ebp
f0104cc1:	c3                   	ret    

f0104cc2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104cc2:	55                   	push   %ebp
f0104cc3:	89 e5                	mov    %esp,%ebp
f0104cc5:	56                   	push   %esi
f0104cc6:	53                   	push   %ebx
f0104cc7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104cca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ccd:	89 f3                	mov    %esi,%ebx
f0104ccf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104cd2:	89 f2                	mov    %esi,%edx
f0104cd4:	eb 0f                	jmp    f0104ce5 <strncpy+0x23>
		*dst++ = *src;
f0104cd6:	83 c2 01             	add    $0x1,%edx
f0104cd9:	0f b6 01             	movzbl (%ecx),%eax
f0104cdc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104cdf:	80 39 01             	cmpb   $0x1,(%ecx)
f0104ce2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ce5:	39 da                	cmp    %ebx,%edx
f0104ce7:	75 ed                	jne    f0104cd6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104ce9:	89 f0                	mov    %esi,%eax
f0104ceb:	5b                   	pop    %ebx
f0104cec:	5e                   	pop    %esi
f0104ced:	5d                   	pop    %ebp
f0104cee:	c3                   	ret    

f0104cef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104cef:	55                   	push   %ebp
f0104cf0:	89 e5                	mov    %esp,%ebp
f0104cf2:	56                   	push   %esi
f0104cf3:	53                   	push   %ebx
f0104cf4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104cf7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cfa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104cfd:	89 f0                	mov    %esi,%eax
f0104cff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104d03:	85 c9                	test   %ecx,%ecx
f0104d05:	75 0b                	jne    f0104d12 <strlcpy+0x23>
f0104d07:	eb 1d                	jmp    f0104d26 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104d09:	83 c0 01             	add    $0x1,%eax
f0104d0c:	83 c2 01             	add    $0x1,%edx
f0104d0f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104d12:	39 d8                	cmp    %ebx,%eax
f0104d14:	74 0b                	je     f0104d21 <strlcpy+0x32>
f0104d16:	0f b6 0a             	movzbl (%edx),%ecx
f0104d19:	84 c9                	test   %cl,%cl
f0104d1b:	75 ec                	jne    f0104d09 <strlcpy+0x1a>
f0104d1d:	89 c2                	mov    %eax,%edx
f0104d1f:	eb 02                	jmp    f0104d23 <strlcpy+0x34>
f0104d21:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104d23:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104d26:	29 f0                	sub    %esi,%eax
}
f0104d28:	5b                   	pop    %ebx
f0104d29:	5e                   	pop    %esi
f0104d2a:	5d                   	pop    %ebp
f0104d2b:	c3                   	ret    

f0104d2c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104d2c:	55                   	push   %ebp
f0104d2d:	89 e5                	mov    %esp,%ebp
f0104d2f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d32:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104d35:	eb 06                	jmp    f0104d3d <strcmp+0x11>
		p++, q++;
f0104d37:	83 c1 01             	add    $0x1,%ecx
f0104d3a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104d3d:	0f b6 01             	movzbl (%ecx),%eax
f0104d40:	84 c0                	test   %al,%al
f0104d42:	74 04                	je     f0104d48 <strcmp+0x1c>
f0104d44:	3a 02                	cmp    (%edx),%al
f0104d46:	74 ef                	je     f0104d37 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d48:	0f b6 c0             	movzbl %al,%eax
f0104d4b:	0f b6 12             	movzbl (%edx),%edx
f0104d4e:	29 d0                	sub    %edx,%eax
}
f0104d50:	5d                   	pop    %ebp
f0104d51:	c3                   	ret    

f0104d52 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104d52:	55                   	push   %ebp
f0104d53:	89 e5                	mov    %esp,%ebp
f0104d55:	53                   	push   %ebx
f0104d56:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d59:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d5c:	89 c3                	mov    %eax,%ebx
f0104d5e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104d61:	eb 06                	jmp    f0104d69 <strncmp+0x17>
		n--, p++, q++;
f0104d63:	83 c0 01             	add    $0x1,%eax
f0104d66:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104d69:	39 d8                	cmp    %ebx,%eax
f0104d6b:	74 15                	je     f0104d82 <strncmp+0x30>
f0104d6d:	0f b6 08             	movzbl (%eax),%ecx
f0104d70:	84 c9                	test   %cl,%cl
f0104d72:	74 04                	je     f0104d78 <strncmp+0x26>
f0104d74:	3a 0a                	cmp    (%edx),%cl
f0104d76:	74 eb                	je     f0104d63 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d78:	0f b6 00             	movzbl (%eax),%eax
f0104d7b:	0f b6 12             	movzbl (%edx),%edx
f0104d7e:	29 d0                	sub    %edx,%eax
f0104d80:	eb 05                	jmp    f0104d87 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104d82:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104d87:	5b                   	pop    %ebx
f0104d88:	5d                   	pop    %ebp
f0104d89:	c3                   	ret    

f0104d8a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104d8a:	55                   	push   %ebp
f0104d8b:	89 e5                	mov    %esp,%ebp
f0104d8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d90:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d94:	eb 07                	jmp    f0104d9d <strchr+0x13>
		if (*s == c)
f0104d96:	38 ca                	cmp    %cl,%dl
f0104d98:	74 0f                	je     f0104da9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104d9a:	83 c0 01             	add    $0x1,%eax
f0104d9d:	0f b6 10             	movzbl (%eax),%edx
f0104da0:	84 d2                	test   %dl,%dl
f0104da2:	75 f2                	jne    f0104d96 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104da4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104da9:	5d                   	pop    %ebp
f0104daa:	c3                   	ret    

f0104dab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104dab:	55                   	push   %ebp
f0104dac:	89 e5                	mov    %esp,%ebp
f0104dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104db1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104db5:	eb 07                	jmp    f0104dbe <strfind+0x13>
		if (*s == c)
f0104db7:	38 ca                	cmp    %cl,%dl
f0104db9:	74 0a                	je     f0104dc5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104dbb:	83 c0 01             	add    $0x1,%eax
f0104dbe:	0f b6 10             	movzbl (%eax),%edx
f0104dc1:	84 d2                	test   %dl,%dl
f0104dc3:	75 f2                	jne    f0104db7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104dc5:	5d                   	pop    %ebp
f0104dc6:	c3                   	ret    

f0104dc7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104dc7:	55                   	push   %ebp
f0104dc8:	89 e5                	mov    %esp,%ebp
f0104dca:	57                   	push   %edi
f0104dcb:	56                   	push   %esi
f0104dcc:	53                   	push   %ebx
f0104dcd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104dd0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104dd3:	85 c9                	test   %ecx,%ecx
f0104dd5:	74 36                	je     f0104e0d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104dd7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104ddd:	75 28                	jne    f0104e07 <memset+0x40>
f0104ddf:	f6 c1 03             	test   $0x3,%cl
f0104de2:	75 23                	jne    f0104e07 <memset+0x40>
		c &= 0xFF;
f0104de4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104de8:	89 d3                	mov    %edx,%ebx
f0104dea:	c1 e3 08             	shl    $0x8,%ebx
f0104ded:	89 d6                	mov    %edx,%esi
f0104def:	c1 e6 18             	shl    $0x18,%esi
f0104df2:	89 d0                	mov    %edx,%eax
f0104df4:	c1 e0 10             	shl    $0x10,%eax
f0104df7:	09 f0                	or     %esi,%eax
f0104df9:	09 c2                	or     %eax,%edx
f0104dfb:	89 d0                	mov    %edx,%eax
f0104dfd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104dff:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104e02:	fc                   	cld    
f0104e03:	f3 ab                	rep stos %eax,%es:(%edi)
f0104e05:	eb 06                	jmp    f0104e0d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104e07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e0a:	fc                   	cld    
f0104e0b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104e0d:	89 f8                	mov    %edi,%eax
f0104e0f:	5b                   	pop    %ebx
f0104e10:	5e                   	pop    %esi
f0104e11:	5f                   	pop    %edi
f0104e12:	5d                   	pop    %ebp
f0104e13:	c3                   	ret    

f0104e14 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104e14:	55                   	push   %ebp
f0104e15:	89 e5                	mov    %esp,%ebp
f0104e17:	57                   	push   %edi
f0104e18:	56                   	push   %esi
f0104e19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e1c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e1f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104e22:	39 c6                	cmp    %eax,%esi
f0104e24:	73 35                	jae    f0104e5b <memmove+0x47>
f0104e26:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104e29:	39 d0                	cmp    %edx,%eax
f0104e2b:	73 2e                	jae    f0104e5b <memmove+0x47>
		s += n;
		d += n;
f0104e2d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104e30:	89 d6                	mov    %edx,%esi
f0104e32:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e34:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104e3a:	75 13                	jne    f0104e4f <memmove+0x3b>
f0104e3c:	f6 c1 03             	test   $0x3,%cl
f0104e3f:	75 0e                	jne    f0104e4f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104e41:	83 ef 04             	sub    $0x4,%edi
f0104e44:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104e47:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104e4a:	fd                   	std    
f0104e4b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e4d:	eb 09                	jmp    f0104e58 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104e4f:	83 ef 01             	sub    $0x1,%edi
f0104e52:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104e55:	fd                   	std    
f0104e56:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104e58:	fc                   	cld    
f0104e59:	eb 1d                	jmp    f0104e78 <memmove+0x64>
f0104e5b:	89 f2                	mov    %esi,%edx
f0104e5d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104e5f:	f6 c2 03             	test   $0x3,%dl
f0104e62:	75 0f                	jne    f0104e73 <memmove+0x5f>
f0104e64:	f6 c1 03             	test   $0x3,%cl
f0104e67:	75 0a                	jne    f0104e73 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104e69:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104e6c:	89 c7                	mov    %eax,%edi
f0104e6e:	fc                   	cld    
f0104e6f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104e71:	eb 05                	jmp    f0104e78 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104e73:	89 c7                	mov    %eax,%edi
f0104e75:	fc                   	cld    
f0104e76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104e78:	5e                   	pop    %esi
f0104e79:	5f                   	pop    %edi
f0104e7a:	5d                   	pop    %ebp
f0104e7b:	c3                   	ret    

f0104e7c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104e7c:	55                   	push   %ebp
f0104e7d:	89 e5                	mov    %esp,%ebp
f0104e7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104e82:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e90:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e93:	89 04 24             	mov    %eax,(%esp)
f0104e96:	e8 79 ff ff ff       	call   f0104e14 <memmove>
}
f0104e9b:	c9                   	leave  
f0104e9c:	c3                   	ret    

f0104e9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104e9d:	55                   	push   %ebp
f0104e9e:	89 e5                	mov    %esp,%ebp
f0104ea0:	56                   	push   %esi
f0104ea1:	53                   	push   %ebx
f0104ea2:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ea5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ea8:	89 d6                	mov    %edx,%esi
f0104eaa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104ead:	eb 1a                	jmp    f0104ec9 <memcmp+0x2c>
		if (*s1 != *s2)
f0104eaf:	0f b6 02             	movzbl (%edx),%eax
f0104eb2:	0f b6 19             	movzbl (%ecx),%ebx
f0104eb5:	38 d8                	cmp    %bl,%al
f0104eb7:	74 0a                	je     f0104ec3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104eb9:	0f b6 c0             	movzbl %al,%eax
f0104ebc:	0f b6 db             	movzbl %bl,%ebx
f0104ebf:	29 d8                	sub    %ebx,%eax
f0104ec1:	eb 0f                	jmp    f0104ed2 <memcmp+0x35>
		s1++, s2++;
f0104ec3:	83 c2 01             	add    $0x1,%edx
f0104ec6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104ec9:	39 f2                	cmp    %esi,%edx
f0104ecb:	75 e2                	jne    f0104eaf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104ecd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ed2:	5b                   	pop    %ebx
f0104ed3:	5e                   	pop    %esi
f0104ed4:	5d                   	pop    %ebp
f0104ed5:	c3                   	ret    

f0104ed6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104ed6:	55                   	push   %ebp
f0104ed7:	89 e5                	mov    %esp,%ebp
f0104ed9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104edc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104edf:	89 c2                	mov    %eax,%edx
f0104ee1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104ee4:	eb 07                	jmp    f0104eed <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ee6:	38 08                	cmp    %cl,(%eax)
f0104ee8:	74 07                	je     f0104ef1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104eea:	83 c0 01             	add    $0x1,%eax
f0104eed:	39 d0                	cmp    %edx,%eax
f0104eef:	72 f5                	jb     f0104ee6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104ef1:	5d                   	pop    %ebp
f0104ef2:	c3                   	ret    

f0104ef3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104ef3:	55                   	push   %ebp
f0104ef4:	89 e5                	mov    %esp,%ebp
f0104ef6:	57                   	push   %edi
f0104ef7:	56                   	push   %esi
f0104ef8:	53                   	push   %ebx
f0104ef9:	8b 55 08             	mov    0x8(%ebp),%edx
f0104efc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104eff:	eb 03                	jmp    f0104f04 <strtol+0x11>
		s++;
f0104f01:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f04:	0f b6 0a             	movzbl (%edx),%ecx
f0104f07:	80 f9 09             	cmp    $0x9,%cl
f0104f0a:	74 f5                	je     f0104f01 <strtol+0xe>
f0104f0c:	80 f9 20             	cmp    $0x20,%cl
f0104f0f:	74 f0                	je     f0104f01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104f11:	80 f9 2b             	cmp    $0x2b,%cl
f0104f14:	75 0a                	jne    f0104f20 <strtol+0x2d>
		s++;
f0104f16:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104f19:	bf 00 00 00 00       	mov    $0x0,%edi
f0104f1e:	eb 11                	jmp    f0104f31 <strtol+0x3e>
f0104f20:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104f25:	80 f9 2d             	cmp    $0x2d,%cl
f0104f28:	75 07                	jne    f0104f31 <strtol+0x3e>
		s++, neg = 1;
f0104f2a:	8d 52 01             	lea    0x1(%edx),%edx
f0104f2d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104f31:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104f36:	75 15                	jne    f0104f4d <strtol+0x5a>
f0104f38:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f3b:	75 10                	jne    f0104f4d <strtol+0x5a>
f0104f3d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104f41:	75 0a                	jne    f0104f4d <strtol+0x5a>
		s += 2, base = 16;
f0104f43:	83 c2 02             	add    $0x2,%edx
f0104f46:	b8 10 00 00 00       	mov    $0x10,%eax
f0104f4b:	eb 10                	jmp    f0104f5d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104f4d:	85 c0                	test   %eax,%eax
f0104f4f:	75 0c                	jne    f0104f5d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104f51:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104f53:	80 3a 30             	cmpb   $0x30,(%edx)
f0104f56:	75 05                	jne    f0104f5d <strtol+0x6a>
		s++, base = 8;
f0104f58:	83 c2 01             	add    $0x1,%edx
f0104f5b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104f5d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104f62:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104f65:	0f b6 0a             	movzbl (%edx),%ecx
f0104f68:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104f6b:	89 f0                	mov    %esi,%eax
f0104f6d:	3c 09                	cmp    $0x9,%al
f0104f6f:	77 08                	ja     f0104f79 <strtol+0x86>
			dig = *s - '0';
f0104f71:	0f be c9             	movsbl %cl,%ecx
f0104f74:	83 e9 30             	sub    $0x30,%ecx
f0104f77:	eb 20                	jmp    f0104f99 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104f79:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104f7c:	89 f0                	mov    %esi,%eax
f0104f7e:	3c 19                	cmp    $0x19,%al
f0104f80:	77 08                	ja     f0104f8a <strtol+0x97>
			dig = *s - 'a' + 10;
f0104f82:	0f be c9             	movsbl %cl,%ecx
f0104f85:	83 e9 57             	sub    $0x57,%ecx
f0104f88:	eb 0f                	jmp    f0104f99 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104f8a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104f8d:	89 f0                	mov    %esi,%eax
f0104f8f:	3c 19                	cmp    $0x19,%al
f0104f91:	77 16                	ja     f0104fa9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104f93:	0f be c9             	movsbl %cl,%ecx
f0104f96:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104f99:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104f9c:	7d 0f                	jge    f0104fad <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104f9e:	83 c2 01             	add    $0x1,%edx
f0104fa1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104fa5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104fa7:	eb bc                	jmp    f0104f65 <strtol+0x72>
f0104fa9:	89 d8                	mov    %ebx,%eax
f0104fab:	eb 02                	jmp    f0104faf <strtol+0xbc>
f0104fad:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104faf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104fb3:	74 05                	je     f0104fba <strtol+0xc7>
		*endptr = (char *) s;
f0104fb5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104fb8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104fba:	f7 d8                	neg    %eax
f0104fbc:	85 ff                	test   %edi,%edi
f0104fbe:	0f 44 c3             	cmove  %ebx,%eax
}
f0104fc1:	5b                   	pop    %ebx
f0104fc2:	5e                   	pop    %esi
f0104fc3:	5f                   	pop    %edi
f0104fc4:	5d                   	pop    %ebp
f0104fc5:	c3                   	ret    
f0104fc6:	66 90                	xchg   %ax,%ax
f0104fc8:	66 90                	xchg   %ax,%ax
f0104fca:	66 90                	xchg   %ax,%ax
f0104fcc:	66 90                	xchg   %ax,%ax
f0104fce:	66 90                	xchg   %ax,%ax

f0104fd0 <__udivdi3>:
f0104fd0:	55                   	push   %ebp
f0104fd1:	57                   	push   %edi
f0104fd2:	56                   	push   %esi
f0104fd3:	83 ec 0c             	sub    $0xc,%esp
f0104fd6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104fda:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104fde:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104fe2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104fe6:	85 c0                	test   %eax,%eax
f0104fe8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104fec:	89 ea                	mov    %ebp,%edx
f0104fee:	89 0c 24             	mov    %ecx,(%esp)
f0104ff1:	75 2d                	jne    f0105020 <__udivdi3+0x50>
f0104ff3:	39 e9                	cmp    %ebp,%ecx
f0104ff5:	77 61                	ja     f0105058 <__udivdi3+0x88>
f0104ff7:	85 c9                	test   %ecx,%ecx
f0104ff9:	89 ce                	mov    %ecx,%esi
f0104ffb:	75 0b                	jne    f0105008 <__udivdi3+0x38>
f0104ffd:	b8 01 00 00 00       	mov    $0x1,%eax
f0105002:	31 d2                	xor    %edx,%edx
f0105004:	f7 f1                	div    %ecx
f0105006:	89 c6                	mov    %eax,%esi
f0105008:	31 d2                	xor    %edx,%edx
f010500a:	89 e8                	mov    %ebp,%eax
f010500c:	f7 f6                	div    %esi
f010500e:	89 c5                	mov    %eax,%ebp
f0105010:	89 f8                	mov    %edi,%eax
f0105012:	f7 f6                	div    %esi
f0105014:	89 ea                	mov    %ebp,%edx
f0105016:	83 c4 0c             	add    $0xc,%esp
f0105019:	5e                   	pop    %esi
f010501a:	5f                   	pop    %edi
f010501b:	5d                   	pop    %ebp
f010501c:	c3                   	ret    
f010501d:	8d 76 00             	lea    0x0(%esi),%esi
f0105020:	39 e8                	cmp    %ebp,%eax
f0105022:	77 24                	ja     f0105048 <__udivdi3+0x78>
f0105024:	0f bd e8             	bsr    %eax,%ebp
f0105027:	83 f5 1f             	xor    $0x1f,%ebp
f010502a:	75 3c                	jne    f0105068 <__udivdi3+0x98>
f010502c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0105030:	39 34 24             	cmp    %esi,(%esp)
f0105033:	0f 86 9f 00 00 00    	jbe    f01050d8 <__udivdi3+0x108>
f0105039:	39 d0                	cmp    %edx,%eax
f010503b:	0f 82 97 00 00 00    	jb     f01050d8 <__udivdi3+0x108>
f0105041:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105048:	31 d2                	xor    %edx,%edx
f010504a:	31 c0                	xor    %eax,%eax
f010504c:	83 c4 0c             	add    $0xc,%esp
f010504f:	5e                   	pop    %esi
f0105050:	5f                   	pop    %edi
f0105051:	5d                   	pop    %ebp
f0105052:	c3                   	ret    
f0105053:	90                   	nop
f0105054:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105058:	89 f8                	mov    %edi,%eax
f010505a:	f7 f1                	div    %ecx
f010505c:	31 d2                	xor    %edx,%edx
f010505e:	83 c4 0c             	add    $0xc,%esp
f0105061:	5e                   	pop    %esi
f0105062:	5f                   	pop    %edi
f0105063:	5d                   	pop    %ebp
f0105064:	c3                   	ret    
f0105065:	8d 76 00             	lea    0x0(%esi),%esi
f0105068:	89 e9                	mov    %ebp,%ecx
f010506a:	8b 3c 24             	mov    (%esp),%edi
f010506d:	d3 e0                	shl    %cl,%eax
f010506f:	89 c6                	mov    %eax,%esi
f0105071:	b8 20 00 00 00       	mov    $0x20,%eax
f0105076:	29 e8                	sub    %ebp,%eax
f0105078:	89 c1                	mov    %eax,%ecx
f010507a:	d3 ef                	shr    %cl,%edi
f010507c:	89 e9                	mov    %ebp,%ecx
f010507e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105082:	8b 3c 24             	mov    (%esp),%edi
f0105085:	09 74 24 08          	or     %esi,0x8(%esp)
f0105089:	89 d6                	mov    %edx,%esi
f010508b:	d3 e7                	shl    %cl,%edi
f010508d:	89 c1                	mov    %eax,%ecx
f010508f:	89 3c 24             	mov    %edi,(%esp)
f0105092:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105096:	d3 ee                	shr    %cl,%esi
f0105098:	89 e9                	mov    %ebp,%ecx
f010509a:	d3 e2                	shl    %cl,%edx
f010509c:	89 c1                	mov    %eax,%ecx
f010509e:	d3 ef                	shr    %cl,%edi
f01050a0:	09 d7                	or     %edx,%edi
f01050a2:	89 f2                	mov    %esi,%edx
f01050a4:	89 f8                	mov    %edi,%eax
f01050a6:	f7 74 24 08          	divl   0x8(%esp)
f01050aa:	89 d6                	mov    %edx,%esi
f01050ac:	89 c7                	mov    %eax,%edi
f01050ae:	f7 24 24             	mull   (%esp)
f01050b1:	39 d6                	cmp    %edx,%esi
f01050b3:	89 14 24             	mov    %edx,(%esp)
f01050b6:	72 30                	jb     f01050e8 <__udivdi3+0x118>
f01050b8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01050bc:	89 e9                	mov    %ebp,%ecx
f01050be:	d3 e2                	shl    %cl,%edx
f01050c0:	39 c2                	cmp    %eax,%edx
f01050c2:	73 05                	jae    f01050c9 <__udivdi3+0xf9>
f01050c4:	3b 34 24             	cmp    (%esp),%esi
f01050c7:	74 1f                	je     f01050e8 <__udivdi3+0x118>
f01050c9:	89 f8                	mov    %edi,%eax
f01050cb:	31 d2                	xor    %edx,%edx
f01050cd:	e9 7a ff ff ff       	jmp    f010504c <__udivdi3+0x7c>
f01050d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01050d8:	31 d2                	xor    %edx,%edx
f01050da:	b8 01 00 00 00       	mov    $0x1,%eax
f01050df:	e9 68 ff ff ff       	jmp    f010504c <__udivdi3+0x7c>
f01050e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050e8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01050eb:	31 d2                	xor    %edx,%edx
f01050ed:	83 c4 0c             	add    $0xc,%esp
f01050f0:	5e                   	pop    %esi
f01050f1:	5f                   	pop    %edi
f01050f2:	5d                   	pop    %ebp
f01050f3:	c3                   	ret    
f01050f4:	66 90                	xchg   %ax,%ax
f01050f6:	66 90                	xchg   %ax,%ax
f01050f8:	66 90                	xchg   %ax,%ax
f01050fa:	66 90                	xchg   %ax,%ax
f01050fc:	66 90                	xchg   %ax,%ax
f01050fe:	66 90                	xchg   %ax,%ax

f0105100 <__umoddi3>:
f0105100:	55                   	push   %ebp
f0105101:	57                   	push   %edi
f0105102:	56                   	push   %esi
f0105103:	83 ec 14             	sub    $0x14,%esp
f0105106:	8b 44 24 28          	mov    0x28(%esp),%eax
f010510a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010510e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0105112:	89 c7                	mov    %eax,%edi
f0105114:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105118:	8b 44 24 30          	mov    0x30(%esp),%eax
f010511c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105120:	89 34 24             	mov    %esi,(%esp)
f0105123:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105127:	85 c0                	test   %eax,%eax
f0105129:	89 c2                	mov    %eax,%edx
f010512b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010512f:	75 17                	jne    f0105148 <__umoddi3+0x48>
f0105131:	39 fe                	cmp    %edi,%esi
f0105133:	76 4b                	jbe    f0105180 <__umoddi3+0x80>
f0105135:	89 c8                	mov    %ecx,%eax
f0105137:	89 fa                	mov    %edi,%edx
f0105139:	f7 f6                	div    %esi
f010513b:	89 d0                	mov    %edx,%eax
f010513d:	31 d2                	xor    %edx,%edx
f010513f:	83 c4 14             	add    $0x14,%esp
f0105142:	5e                   	pop    %esi
f0105143:	5f                   	pop    %edi
f0105144:	5d                   	pop    %ebp
f0105145:	c3                   	ret    
f0105146:	66 90                	xchg   %ax,%ax
f0105148:	39 f8                	cmp    %edi,%eax
f010514a:	77 54                	ja     f01051a0 <__umoddi3+0xa0>
f010514c:	0f bd e8             	bsr    %eax,%ebp
f010514f:	83 f5 1f             	xor    $0x1f,%ebp
f0105152:	75 5c                	jne    f01051b0 <__umoddi3+0xb0>
f0105154:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0105158:	39 3c 24             	cmp    %edi,(%esp)
f010515b:	0f 87 e7 00 00 00    	ja     f0105248 <__umoddi3+0x148>
f0105161:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105165:	29 f1                	sub    %esi,%ecx
f0105167:	19 c7                	sbb    %eax,%edi
f0105169:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010516d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105171:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105175:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105179:	83 c4 14             	add    $0x14,%esp
f010517c:	5e                   	pop    %esi
f010517d:	5f                   	pop    %edi
f010517e:	5d                   	pop    %ebp
f010517f:	c3                   	ret    
f0105180:	85 f6                	test   %esi,%esi
f0105182:	89 f5                	mov    %esi,%ebp
f0105184:	75 0b                	jne    f0105191 <__umoddi3+0x91>
f0105186:	b8 01 00 00 00       	mov    $0x1,%eax
f010518b:	31 d2                	xor    %edx,%edx
f010518d:	f7 f6                	div    %esi
f010518f:	89 c5                	mov    %eax,%ebp
f0105191:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105195:	31 d2                	xor    %edx,%edx
f0105197:	f7 f5                	div    %ebp
f0105199:	89 c8                	mov    %ecx,%eax
f010519b:	f7 f5                	div    %ebp
f010519d:	eb 9c                	jmp    f010513b <__umoddi3+0x3b>
f010519f:	90                   	nop
f01051a0:	89 c8                	mov    %ecx,%eax
f01051a2:	89 fa                	mov    %edi,%edx
f01051a4:	83 c4 14             	add    $0x14,%esp
f01051a7:	5e                   	pop    %esi
f01051a8:	5f                   	pop    %edi
f01051a9:	5d                   	pop    %ebp
f01051aa:	c3                   	ret    
f01051ab:	90                   	nop
f01051ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01051b0:	8b 04 24             	mov    (%esp),%eax
f01051b3:	be 20 00 00 00       	mov    $0x20,%esi
f01051b8:	89 e9                	mov    %ebp,%ecx
f01051ba:	29 ee                	sub    %ebp,%esi
f01051bc:	d3 e2                	shl    %cl,%edx
f01051be:	89 f1                	mov    %esi,%ecx
f01051c0:	d3 e8                	shr    %cl,%eax
f01051c2:	89 e9                	mov    %ebp,%ecx
f01051c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051c8:	8b 04 24             	mov    (%esp),%eax
f01051cb:	09 54 24 04          	or     %edx,0x4(%esp)
f01051cf:	89 fa                	mov    %edi,%edx
f01051d1:	d3 e0                	shl    %cl,%eax
f01051d3:	89 f1                	mov    %esi,%ecx
f01051d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01051d9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01051dd:	d3 ea                	shr    %cl,%edx
f01051df:	89 e9                	mov    %ebp,%ecx
f01051e1:	d3 e7                	shl    %cl,%edi
f01051e3:	89 f1                	mov    %esi,%ecx
f01051e5:	d3 e8                	shr    %cl,%eax
f01051e7:	89 e9                	mov    %ebp,%ecx
f01051e9:	09 f8                	or     %edi,%eax
f01051eb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01051ef:	f7 74 24 04          	divl   0x4(%esp)
f01051f3:	d3 e7                	shl    %cl,%edi
f01051f5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01051f9:	89 d7                	mov    %edx,%edi
f01051fb:	f7 64 24 08          	mull   0x8(%esp)
f01051ff:	39 d7                	cmp    %edx,%edi
f0105201:	89 c1                	mov    %eax,%ecx
f0105203:	89 14 24             	mov    %edx,(%esp)
f0105206:	72 2c                	jb     f0105234 <__umoddi3+0x134>
f0105208:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010520c:	72 22                	jb     f0105230 <__umoddi3+0x130>
f010520e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105212:	29 c8                	sub    %ecx,%eax
f0105214:	19 d7                	sbb    %edx,%edi
f0105216:	89 e9                	mov    %ebp,%ecx
f0105218:	89 fa                	mov    %edi,%edx
f010521a:	d3 e8                	shr    %cl,%eax
f010521c:	89 f1                	mov    %esi,%ecx
f010521e:	d3 e2                	shl    %cl,%edx
f0105220:	89 e9                	mov    %ebp,%ecx
f0105222:	d3 ef                	shr    %cl,%edi
f0105224:	09 d0                	or     %edx,%eax
f0105226:	89 fa                	mov    %edi,%edx
f0105228:	83 c4 14             	add    $0x14,%esp
f010522b:	5e                   	pop    %esi
f010522c:	5f                   	pop    %edi
f010522d:	5d                   	pop    %ebp
f010522e:	c3                   	ret    
f010522f:	90                   	nop
f0105230:	39 d7                	cmp    %edx,%edi
f0105232:	75 da                	jne    f010520e <__umoddi3+0x10e>
f0105234:	8b 14 24             	mov    (%esp),%edx
f0105237:	89 c1                	mov    %eax,%ecx
f0105239:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010523d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105241:	eb cb                	jmp    f010520e <__umoddi3+0x10e>
f0105243:	90                   	nop
f0105244:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105248:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010524c:	0f 82 0f ff ff ff    	jb     f0105161 <__umoddi3+0x61>
f0105252:	e9 1a ff ff ff       	jmp    f0105171 <__umoddi3+0x71>
