## EDM: The <u>E</u>ndec <u>D</u>ata <u>M</u>odel Format

EDM is a common format for endec which precisely encapsulates the 12 primitive and 4 compound data types of the endec data model. In accordance with the data model, the following types are supported:

| Type     | Meaning                                           |
|----------|---------------------------------------------------|
| u8       | Unsigned 8-bit integer (byte)                     |
| i8       | Signed 8-bit integer (byte)                       |
| u16      | Unsigned 16-bit integer                           |
| i16      | Signed 16-bit integer                             |
| u32      | Unsigned 32-bit integer                           |
| i32      | Signed 32-bit integer                             |
| u64      | Unsigned 64-bit integer                           |
| i64      | Signed 64-bit integer                             |
| f32      | Single-precision IEEE-754 floating point number   |
| f64      | Double-precision IEEE-754 floating point number   |
| boolean  | true or false, a single bit                       |
| string   | Length-prefixed, UTF-8 encoded character sequence |
| bytes    | Size-prefixed byte array                          |
| optional | A single other value or nothing                   |
| sequence | Length-prefixed sequence of values                |
| map      | Length-prefixed sequence of key-value pairs       |


### Textual representation

The following EBNF describes the textual representation of EDM:

```ebnf
element                 = int | float | boolean | string | bytes | optional | sequence | map ;

(* numbers *)
nonzero-digit           = [1-9] ;
digit                   = '0' | nonzero-digit ;

natural                 = '0' | nonzero-digit digit* ;
integer                 = '-'? natural ;

unsigned-int            = ('u8' | 'u16' | 'u32' | 'u64') '(' natural ')' ;
signed-int              = ('i8' | 'i16' | 'i32' | 'i64') '(' integer ')' ;
int                     = unsigned-int | signed-int ;

rational                = integer ( '.' natural )? ;
float                   = 'f' ( '32' | '64' ) '(' rational ')' ;

(* other primitives *)
boolean                 = 'true' | 'false' ;

string-char             = ? any character ? - '"' | '\"' ;
string                  = 'string("' string-char* '")' ;

base-sixtyfour-digit    = [A-Za-z] | digit | '+' | '/' ;
bytes                   = 'bytes(' base-sixtyfour-digit* ')' ;

(* compound types *)
optional                = 'optional(' element? ')' ;

elements                = element ',' elements | element ','? ;
sequence                = 'sequence([' elements? '])';

map-entry               = '"' string-char* '":' element ;
map-entries             = map-entry ',' map-entries | map-entry ','? ;
map                     = 'map({' map-entries? '})';
```

### Binary representation

```ebnf
(* u<n> is an unsigned integer of width n            *)
(* i<n> is a signed integer of width n               *)
(* all integers are little-endian encoded            *)

(* f32 is a single-precision float                   *)
(* f64 is a double-precision float                   *)
(* all floats are encoded as in IEEE-754             *)

(* <n>b refers to a literal unsigned byte of value n *)

element             := int | float | boolean | string | bytes | optional | sequence | map ;

int                 := 0b i8
                     | 1b u8
                     | 2b i16
                     | 3b u16
                     | 4b i32
                     | 5b u32
                     | 6b i64
                     | 7b u64 ;
float               := 8b f32
                     | 9b f64 ;

boolean             := 10b ( 0b | 1b ) ;
string-data         := u16 u8* ;
string              := 11b string-data ;
bytes               := 12b u32 u8* ;

optional            := 13b ( 0b | 1b element );
sequence            := 14b u32 element* ;
map                 := 15b u32 ( string-data element )* ;
```