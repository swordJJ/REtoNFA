theory AReg imports Main  begin

declare Let_def [simp]

section "Regexp definition and semantics"

datatype ('v)regexp = ESet |(* EString |*) LChr 'v| Concat "'v regexp" "'v regexp"|
                      Alter "('v) regexp" "('v) regexp" (infix "||" 55) | Dot|
                      Star "'v regexp" | Plus "('v) regexp"("_+") | Ques "('v) regexp"("_?")          

inductive_set star :: "'v list set \<Rightarrow> 'v list set" 
  for r :: "'v list set" where
zero[intro!]:"[] \<in> star r"|
step[intro!]:"x \<in> r \<and> y \<in> star r \<Longrightarrow> x@y \<in> star r"

primrec sem_reg :: "('v) regexp => 'v set\<Rightarrow> 'v list set" where 
"sem_reg ESet v = {}"| (*Empty Set*)
(*"sem_reg EString v = {[]}"| (*Empty String*)*)
"sem_reg (Dot) vset = (λu. [u]) ` vset" | 
"sem_reg (Concat r1 r2) v =(λu. fst u @ snd u) ` (sem_reg r1 v × sem_reg r2 v)"|
"sem_reg (LChr a) v = {[a]}"|
"sem_reg (v1||v2) a = (sem_reg v1 a) \<union> (sem_reg v2 a)"|
"sem_reg (Star a) v = star (sem_reg a v)"|
"sem_reg (Plus a) v = (sem_reg a v) \<union> star (sem_reg a v)  "|
"sem_reg (Ques v) a = {[]} \<union> (sem_reg v a)"

fun f ::"'v set \<Rightarrow> 'v set\<Rightarrow> ('v * 'v)set" where
"f s1 s2 = {(x,y). x \<in> s1 \<and> y \<in> s2}" 

primrec  alp_reg :: "'v regexp \<Rightarrow> 'v set \<Rightarrow> 'v set" where
"alp_reg (LChr n) vs=  {n}"|
"alp_reg (ESet) vs = {}"|
(*"alp_reg (EString) vs = {}"|*)
"alp_reg (Concat r1 r2) vs =  (alp_reg r1 vs \<union> alp_reg r2 vs)"|
"alp_reg (v1||v2) vs = alp_reg v1 vs \<union> alp_reg v2 vs"|
"alp_reg (Dot) vs = vs"|
"alp_reg (Star v) vs = alp_reg v vs"| 
"alp_reg (Plus v) vs = alp_reg v vs"|
"alp_reg (Ques v) vs = alp_reg v vs"

end