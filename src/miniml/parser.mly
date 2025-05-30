%{
  open Syntax
%}

%token TINT
%token TBOOL
%token TARROW
%token TEXPTN
%token <Syntax.name> VAR
%token <int> INT
%token TRUE FALSE
%token PLUS
%token MINUS
%token TIMES
%token PIPE
%token BY
%token EQUAL LESS
%token IF THEN ELSE
%token TRY WITH
%token FUN IS
%token COLON
%token LPAREN RPAREN
%token LBRACE RBRACE
%token DIVZERO
%token GENEXPTN
%token LET
%token SEMISEMI
%token EOF
%token RAISE

%start file
%type <Syntax.command list> file

%start toplevel
%type <Syntax.command> toplevel

%nonassoc IS
%nonassoc ELSE
%nonassoc EQUAL LESS
%left PLUS MINUS
%left TIMES
%right TARROW

%%

file:
  | EOF
    { [] }
  | e = expr EOF
    { [Expr e] }
  | e = expr SEMISEMI lst = file
    { Expr e :: lst }
  | ds = nonempty_list(def) SEMISEMI lst = file
    { ds @ lst }
  | ds = nonempty_list(def) EOF
    { ds }

toplevel:
  | d = def SEMISEMI
    { d }
  | e = expr SEMISEMI
    { Expr e }

def:
  | LET x = VAR EQUAL e = expr
    { Def (x, e) }

expr: mark_position(plain_expr) { $1 }
plain_expr:
  | e = plain_app_expr
    { e }
  | MINUS n = INT
    { Int (-n) }
  | e1 = expr PLUS e2 = expr	
    { Plus (e1, e2) }
  | e1 = expr MINUS e2 = expr
    { Minus (e1, e2) }
  | e1 = expr TIMES e2 = expr
    { Times (e1, e2) }
  | e1 = expr BY e2 = expr
    { By (e1, e2) }
  | e1 = expr EQUAL e2 = expr
    { Equal (e1, e2) }
  | e1 = expr LESS e2 = expr
    { Less (e1, e2) }
  | IF e1 = expr THEN e2 = expr ELSE e3 = expr
    { If (e1, e2, e3) }
  | FUN x = VAR LPAREN f = VAR COLON t1 = ty RPAREN COLON t2 = ty IS e = expr
    { Fun (x, f, t1, t2, e) }
  | RAISE e = exptn
    { Raise e }
  | TRY e = expr WITH LBRACE cases = nonempty_list(case) RBRACE
    { Try (e, cases) }

case:
  | PIPE e=exptn TARROW e1=expr
    { (e, e1) }

app_expr: mark_position(plain_app_expr) { $1 }
plain_app_expr:
  | e = plain_simple_expr
    { e }
  | e1 = app_expr e2 = simple_expr
    { Apply (e1, e2) }

simple_expr: mark_position(plain_simple_expr) { $1 }
plain_simple_expr:
  | x = exptn
    { Exptn x }
  | x = VAR
    { Var x }
  | TRUE    
    { Bool true }
  | FALSE
    { Bool false }
  | n = INT
    { Int n }
  | LPAREN e = plain_expr RPAREN	
    { e }    
  | LBRACE e = plain_expr RBRACE
    { e }

exptn:
  | DIVZERO
    { DivisionByZero }
  | GENEXPTN e = INT
    { GenericException e }
  | GENEXPTN MINUS e = INT
    { GenericException (-e) }
  | LPAREN e = exptn RPAREN
    { e }

ty:
  | TBOOL
    { TBool }
  | TINT
    { TInt }
  | TEXPTN
    { TExptn }
  | t1 = ty TARROW t2 = ty
    { TArrow (t1, t2) }
  | LPAREN t = ty RPAREN
    { t }
  | LBRACE t = ty RBRACE
    { t }

mark_position(X):
  x = X
  { Zoo.locate ~loc:(Zoo.make_location $startpos $endpos) x }

%%