	
%{
  import java.io.*;
  import java.util.ArrayList;
  import java.util.Stack;
%}


%token ID, INT, FLOAT, BOOL, NUM, LIT, VOID, MAIN, READ, WRITE, IF, ELSE
%token WHILE,TRUE, FALSE, IF, ELSE
%token DO
%token EQ, LEQ, GEQ, NEQ 
%token AND, OR
%token RETURN, BREAK, FOR, CONTINUE

%right '='
%left OR
%left AND
%left  '>' '<' EQ LEQ GEQ NEQ
%left '+' '-'
%left '++' '--'
%left '+='
%left '?' ':'
%left '*' '/' '%'
%left '!' 

%type <sval> ID
%type <sval> LIT
%type <sval> NUM
%type <ival> type
%type <sval> exp
%type <sval> optExp


%%

prog : { geraInicio(); } dList mainF { geraAreaDados(); geraAreaLiterais(); } ;

mainF : VOID MAIN '(' ')'   { System.out.println("_start:"); }
        '{' lcmd  { geraFinal(); } '}'
         ; 

dList : decl dList | ;

decl : type ID ';' {  TS_entry nodo = ts.pesquisa($2);
    	                if (nodo != null) 
                            yyerror("(sem) variavel >" + $2 + "< jah declarada");
                        else ts.insert(new TS_entry($2, $1)); }
      ;

type : INT    { $$ = INT; }
     | FLOAT  { $$ = FLOAT; }
     | BOOL   { $$ = BOOL; }
     ;

lcmd : lcmd cmd
	   |
	   ;
	   
cmd : exp	';' { System.out.println("\tPOPL %EDX");}
			| '{' lcmd '}' { System.out.println("\t\t# terminou o bloco..."); }
			| DO {
    				pRot.push(proxRot); proxRot += 2; // Gera dois rótulos reservados: um para o início do laço (rot_X) e outro (futuro) para o fim se necessário. Armazena rot_X na pilha pRot, que será usado depois no JNE.
    				System.out.printf("rot_%02d:\n", pRot.peek()); // Imprime o rótulo do início do laço.
			} 
		cmd WHILE '(' exp ')' ';' {
    		System.out.println("\tPOPL %EAX"); // Retira da pilha o resultado da condição (exp após o while).
    		System.out.println("\tCMPL $0, %EAX"); // Compara o valor da condição com 0. Se igual a 0 (falso), não repete. Se diferente de 0 (verdadeiro), salta para o início do laço.
    		System.out.printf("\tJNE rot_%02d\n", pRot.peek()); // JNE = Jump if Not Equal → só salta se o resultado não for zero. Vai para rot_X, o início do do
    		pRot.pop(); // Remove o rótulo da pilha (limpeza de controle de fluxo).
			}
					     
					       
      | WRITE '(' LIT ')' ';' { strTab.add($3);
                                System.out.println("\tMOVL $_str_"+strCount+"Len, %EDX"); 
				System.out.println("\tMOVL $_str_"+strCount+", %ECX"); 
                                System.out.println("\tCALL _writeLit"); 
				System.out.println("\tCALL _writeln"); 
                                strCount++;
				}
      
	  | WRITE '(' LIT 
                              { strTab.add($3);
                                System.out.println("\tMOVL $_str_"+strCount+"Len, %EDX"); 
				System.out.println("\tMOVL $_str_"+strCount+", %ECX"); 
                                System.out.println("\tCALL _writeLit"); 
				strCount++;
				}

                    ',' exp ')' ';' 
			{ 
			 System.out.println("\tPOPL %EAX"); 
			 System.out.println("\tCALL _write");	
			 System.out.println("\tCALL _writeln"); 
                        }
         
     | READ '(' ID ')' ';'								
								{
									System.out.println("\tPUSHL $_"+$3);
									System.out.println("\tCALL _read");
									System.out.println("\tPOPL %EDX");
									System.out.println("\tMOVL %EAX, (%EDX)");
									
								}
    | FOR '(' optExp ';' optExp ';' optExp ')' {
		// 1. Gera rótulos para inicialização, condição, incremento e fim do laço
		int rotCond = proxRot++;   // Rótulo para checar a condição
		int rotInc  = proxRot++;   // Rótulo para o incremento
		int rotEnd  = proxRot++;   // Rótulo para sair do laço (fim)
		
		// 2. Empilha os rótulos de controle do laço
		pRot.push(rotEnd);         // Usado para salto no fim
		pInc.push(rotInc);         // Usado para ir para incremento

		// 3. A inicialização foi processada em optExp (se houver)
		// Não precisa repetir aqui — já foi gerado

		// 4. Vai para o teste da condição
		System.out.printf("rot_%02d:\n", rotCond);

		// 5. A condição também foi gerada (se optExp não for null)
		// Agora desempilha o valor da condição
		System.out.println("\tPOPL %EAX");              // Retira o valor da condição da pilha
		System.out.println("\tCMPL $0, %EAX");          // Compara com zero
		System.out.printf("\tJE rot_%02d\n", rotEnd);   // Se for zero (falso), salta para fora
	}	cmd {
			// 6. Após o corpo do laço, vai para incremento
			System.out.printf("rot_%02d:\n", pInc.peek());

			// 7. O incremento foi gerado em optExp (se houver)
			// Ele atualiza a variável de controle

			// 8. Volta para testar a condição novamente
			System.out.printf("\tJMP rot_%02d\n", rotCond);

			// 9. Rótulo do fim do laço
			System.out.printf("rot_%02d:\n", pRot.peek());

			// 10. Desempilha os rótulos do for (necessário para suportar fors aninhados)
			pInc.pop();
			pRot.pop();
		}

	| DO {
    		pRot.push(proxRot); proxRot += 2; // Gera dois rótulos reservados: um para o início do laço (rot_X) e outro (futuro) para o fim se necessário. Armazena rot_X na pilha pRot, que será usado depois no JNE.
    		System.out.printf("rot_%02d:\n", pRot.peek()); // Imprime o rótulo do início do laço.
} 
	|WHILE '(' exp ')' ';' {
    		System.out.println("\tPOPL %EAX"); // Retira da pilha o resultado da condição (exp após o while).
    		System.out.println("\tCMPL $0, %EAX"); // Compara o valor da condição com 0. Se igual a 0 (falso), não repete. Se diferente de 0 (verdadeiro), salta para o início do laço.
    		System.out.printf("\tJNE rot_%02d\n", pRot.peek()); // JNE = Jump if Not Equal → só salta se o resultado não for zero. Vai para rot_X, o início do do
    		pRot.pop(); // Remove o rótulo da pilha (limpeza de controle de fluxo).
}
	;


    | WHILE {
					pRot.push(proxRot);  proxRot += 2;
					System.out.printf("rot_%02d:\n",pRot.peek());
				  } 
			 '(' exp ')' {
			 							System.out.println("\tPOPL %EAX   # desvia se falso...");
											System.out.println("\tCMPL $0, %EAX");
											System.out.printf("\tJE rot_%02d\n", (int)pRot.peek()+1);
										} 
				cmd		{
				  		System.out.printf("\tJMP rot_%02d   # terminou cmd na linha de cima\n", pRot.peek());
							System.out.printf("rot_%02d:\n",(int)pRot.peek()+1);
							pRot.pop();
							}  
							
			| IF '(' exp {	
											pRot.push(proxRot);  proxRot += 2;
															
											System.out.println("\tPOPL %EAX");
											System.out.println("\tCMPL $0, %EAX");
											System.out.printf("\tJE rot_%02d\n", pRot.peek());
										}
								')' cmd 

             restoIf {
											System.out.printf("rot_%02d:\n",pRot.peek()+1);
											pRot.pop();
										}
     ;
     
     
restoIf : ELSE  {
											System.out.printf("\tJMP rot_%02d\n", pRot.peek()+1);
											System.out.printf("rot_%02d:\n",pRot.peek());
								
										} 							
							cmd  
							
							
		| {
		    System.out.printf("\tJMP rot_%02d\n", pRot.peek()+1);
				System.out.printf("rot_%02d:\n",pRot.peek());
				} 
		;										


exp :  NUM  { System.out.println("\tPUSHL $"+$1); } 
    |  TRUE  { System.out.println("\tPUSHL $1"); } 
    |  FALSE  { System.out.println("\tPUSHL $0"); }      
    | ID   { System.out.println("\tPUSHL _"+$1); }
    | ID '=' exp { System.out.println("\tPOPL %EDX");
  		   System.out.println("\tMOVL %EDX, _"+$1);

		   System.out.println("\tPUSHL %EDX");
	         }
    | ID '++' { System.out.println("\tINCL _"+$1);
    		System.out.println("\tPUSHL _"+$1); }
    | '++' ID { System.out.println("\tINCL _"+$2);
    		System.out.println("\tPUSHL _"+$2); }
    | ID '--' { System.out.println("\tDECL _"+$1);
    		System.out.println("\tPUSHL _"+$1); }
    | '--' ID { System.out.println("\tDECL _"+$2);
    		System.out.println("\tPUSHL _"+$2); }
    | ID "+=" exp { // a += b
    		System.out.println("\tPOPL %EDX"); // Tira da pilha o valor da expressão exp (ou seja, o valor de b) e coloca em %EDX.
    		System.out.println("\tMOVL _"+$1+", %EAX"); // Carrega o valor da variável ID (ex: a) da memória para o registrador %EAX.
    		System.out.println("\tADDL %EDX, %EAX"); // Soma o valor de %EDX (que é b) com %EAX (que é a). O resultado de a + b fica agora em %EAX.
    		System.out.println("\tMOVL %EAX, _"+$1); // Armazena o novo valor (soma) de volta na variável a.
    		System.out.println("\tPUSHL %EAX"); // Empilha o resultado da operação a += b novamente na pilha.
		}
    | exp '?' exp ':' exp {
				int rot1 = proxRot++;
    				int rot2 = proxRot++;
    				System.out.println("\tPOPL %EAX"); // condição
    				System.out.println("\tCMPL $0, %EAX");
    				System.out.printf("\tJE rot_%02d\n", rot1);
    // se verdadeiro
    				System.out.println("\tPOPL %EAX"); // expr verdadeira
    				System.out.printf("\tJMP rot_%02d\n", rot2);
    // se falso
    				System.out.printf("rot_%02d:\n", rot1);
    				System.out.println("\tPOPL %EAX"); // expr falsa
    // fim
    				System.out.printf("rot_%02d:\n", rot2);
    				System.out.println("\tPUSHL %EAX");
    			}
    | '(' exp	')' 
    | '!' exp       { gcExpNot(); }
     
		| exp '+' exp		{ gcExpArit('+'); }
		| exp '-' exp		{ gcExpArit('-'); }
		| exp '*' exp		{ gcExpArit('*'); }
		| exp '/' exp		{ gcExpArit('/'); }
		| exp '%' exp		{ gcExpArit('%'); }
																			
		| exp '>' exp		{ gcExpRel('>'); }
		| exp '<' exp		{ gcExpRel('<'); }											
		| exp EQ exp		{ gcExpRel(EQ); }											
		| exp LEQ exp		{ gcExpRel(LEQ); }											
		| exp GEQ exp		{ gcExpRel(GEQ); }											
		| exp NEQ exp		{ gcExpRel(NEQ); }											
												
		| exp OR exp		{ gcExpLog(OR); }											
		| exp AND exp		{ gcExpLog(AND); }											
		
		;		

optExp:
      exp   {  }    // passa o valor da expressão como string
    |       {  }  // define explicitamente como null
    ;
					


%%

  private Yylex lexer;

  private TabSimb ts = new TabSimb();

  private int strCount = 0;
  private ArrayList<String> strTab = new ArrayList<String>();

  private Stack<Integer> pRot = new Stack<Integer>();
  private int proxRot = 1;

  private Stack<Integer> pInc = new Stack<Integer>();
  private int rotInicio;

  public static int ARRAY = 100;


  private int yylex () {
    int yyl_return = -1;
    try {
      yylval = new ParserVal(0);
      yyl_return = lexer.yylex();
    }
    catch (IOException e) {
      System.err.println("IO error :"+e);
    }
    return yyl_return;
  }


  public void yyerror (String error) {
    System.err.println ("Error: " + error + "  linha: " + lexer.getLine());
  }


  public Parser(Reader r) {
    lexer = new Yylex(r, this);
  }  

  public void setDebug(boolean debug) {
    yydebug = debug;
  }

  public void listarTS() { ts.listar();}

  public static void main(String args[]) throws IOException {

    Parser yyparser;
    if ( args.length > 0 ) {
      // parse a file
      yyparser = new Parser(new FileReader(args[0]));
      yyparser.yyparse();
      // yyparser.listarTS();

    }
    else {
      // interactive mode
      System.out.println("\n\tFormato: java Parser entrada.cmm >entrada.s\n");
    }

  }

							
		void gcExpArit(int oparit) {
 				System.out.println("\tPOPL %EBX");
   			System.out.println("\tPOPL %EAX");

   		System.out.println("\tPUSHL %EAX");
		}

	public void gcExpRel(int oprel) {

    System.out.println("\tPOPL %EAX");
    System.out.println("\tPOPL %EDX");
    System.out.println("\tCMPL %EAX, %EDX");
    System.out.println("\tMOVL $0, %EAX");
    
    
    System.out.println("\tPUSHL %EAX");

	}


	public void gcExpLog(int oplog) {

	   	System.out.println("\tPOPL %EDX");
 		 	System.out.println("\tPOPL %EAX");

  	 	System.out.println("\tCMPL $0, %EAX");
 		  System.out.println("\tMOVL $0, %EAX");
   		System.out.println("\tSETNE %AL");
   		System.out.println("\tCMPL $0, %EDX");
   		System.out.println("\tMOVL $0, %EDX");
   		System.out.println("\tSETNE %DL");


    	System.out.println("\tPUSHL %EAX");
	}

	public void gcExpNot(){

  	 System.out.println("\tPOPL %EAX" );
 	   System.out.println("	\tNEGL %EAX" );
  	 System.out.println("	\tPUSHL %EAX");
	}

   private void geraInicio() {
			System.out.println(".text\n\n#\t nome COMPLETO e matricula dos componentes do grupo...\n#\n"); 
			System.out.println(".GLOBL _start\n\n");  
   }

   private void geraFinal(){
	
			System.out.println("\n\n");
			System.out.println("#");
			System.out.println("# devolve o controle para o SO (final da main)");
			System.out.println("#");
			System.out.println("\tmov $0, %ebx");
			System.out.println("\tmov $1, %eax");
			System.out.println("\tint $0x80");
	
			System.out.println("\n");
			System.out.println("#");
			System.out.println("# Funcoes da biblioteca (IO)");
			System.out.println("#");
			System.out.println("\n");
			System.out.println("_writeln:");
			System.out.println("\tMOVL $__fim_msg, %ECX");
			System.out.println("\tDECL %ECX");
			System.out.println("\tMOVB $10, (%ECX)");
			System.out.println("\tMOVL $1, %EDX");
			System.out.println("\tJMP _writeLit");
			System.out.println("_write:");
			System.out.println("\tMOVL $__fim_msg, %ECX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tCMPL $0, %EAX");
			System.out.println("\tJGE _write3");
			System.out.println("\tNEGL %EAX");
			System.out.println("\tMOVL $1, %EBX");
			System.out.println("_write3:");
			System.out.println("\tPUSHL %EBX");
			System.out.println("\tMOVL $10, %EBX");
			System.out.println("_divide:");
			System.out.println("\tMOVL $0, %EDX");
			System.out.println("\tIDIVL %EBX");
			System.out.println("\tDECL %ECX");
			System.out.println("\tADD $48, %DL");
			System.out.println("\tMOVB %DL, (%ECX)");
			System.out.println("\tCMPL $0, %EAX");
			System.out.println("\tJNE _divide");
			System.out.println("\tPOPL %EBX");
			System.out.println("\tCMPL $0, %EBX");
			System.out.println("\tJE _print");
			System.out.println("\tDECL %ECX");
			System.out.println("\tMOVB $'-', (%ECX)");
			System.out.println("_print:");
			System.out.println("\tMOVL $__fim_msg, %EDX");
			System.out.println("\tSUBL %ECX, %EDX");
			System.out.println("_writeLit:");
			System.out.println("\tMOVL $1, %EBX");
			System.out.println("\tMOVL $4, %EAX");
			System.out.println("\tint $0x80");
			System.out.println("\tRET");
			System.out.println("_read:");
			System.out.println("\tMOVL $15, %EDX");
			System.out.println("\tMOVL $__msg, %ECX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tMOVL $3, %EAX");
			System.out.println("\tint $0x80");
			System.out.println("\tMOVL $0, %EAX");
			System.out.println("\tMOVL $0, %EBX");
			System.out.println("\tMOVL $0, %EDX");
			System.out.println("\tMOVL $__msg, %ECX");
			System.out.println("\tCMPB $'-', (%ECX)");
			System.out.println("\tJNE _reading");
			System.out.println("\tINCL %ECX");
			System.out.println("\tINC %BL");
			System.out.println("_reading:");
			System.out.println("\tMOVB (%ECX), %DL");
			System.out.println("\tCMP $10, %DL");
			System.out.println("\tJE _fimread");
			System.out.println("\tSUB $48, %DL");
			System.out.println("\tIMULL $10, %EAX");
			System.out.println("\tADDL %EDX, %EAX");
			System.out.println("\tINCL %ECX");
			System.out.println("\tJMP _reading");
			System.out.println("_fimread:");
			System.out.println("\tCMPB $1, %BL");
			System.out.println("\tJNE _fimread2");
			System.out.println("\tNEGL %EAX");
			System.out.println("_fimread2:");
			System.out.println("\tRET");
			System.out.println("\n");
     }

     private void geraAreaDados(){
			System.out.println("");		
			System.out.println("#");
			System.out.println("# area de dados");
			System.out.println("#");
			System.out.println(".data");
			System.out.println("#");
			System.out.println("# variaveis globais");
			System.out.println("#");
			ts.geraGlobais();	
			System.out.println("");
	
    }

     private void geraAreaLiterais() { 

         System.out.println("#\n# area de literais\n#");
         System.out.println("__msg:");
	       System.out.println("\t.zero 30");
	       System.out.println("__fim_msg:");
	       System.out.println("\t.byte 0");
	       System.out.println("\n");

         for (int i = 0; i<strTab.size(); i++ ) {
             System.out.println("_str_"+i+":");
             System.out.println("\t .ascii \""+strTab.get(i)+"\""); 
	           System.out.println("_str_"+i+"Len = . - _str_"+i);  
	      }		
   }
   
