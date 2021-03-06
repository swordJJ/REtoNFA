theory reg2nfa 
  imports AReg NFA
begin

section "definition of nondeterministic finite automaton"

fun ConcatRegexp :: "'v regexp \<Rightarrow> 'v regexp\<Rightarrow> 'v regexp" where
  "ConcatRegexp r1 r2 = Concat r2 r1"

fun ConcatRegexp2 :: "'v regexp \<Rightarrow> 'v regexp\<Rightarrow> 'v regexp" where
  "ConcatRegexp2 r1 r2 = Concat (Concat r2 r1) r1"

fun renameDelta1 :: "('v regexp * 'v set * 'v regexp) set \<Rightarrow> ('v regexp => 'v regexp)  \<Rightarrow> ('v regexp *'v set *'v regexp) set" where 
    "renameDelta1 ss f = {(f q,v, f q')| q v q' . (q, v, q')\<in> ss}"

fun renameDelta2 :: "('v regexp * 'v regexp) set \<Rightarrow> ('v regexp => 'v regexp)  \<Rightarrow> ('v regexp  *'v regexp) set" where  
    "renameDelta2 ss f = {(f q, f q')| q q'.(q, q')\<in> ss}"

fun getType :: "'v regexp \<Rightarrow> t_regexp" where 
  "getType (LChr v) = t_LChr"|
  "getType (ESet) = t_ESet"|
  "getType \<epsilon> = t_\<epsilon>"|
  "getType Dot = t_Dot"|
  "getType (Concat r1 r2) = t_Concat"|
  "getType (Alter r1 r2) = t_Alter"|
  "getType (Star r) = t_Star"|
  "getType (Plus r) = t_Plus"|
  "getType (Ques r) = t_Ques"

primrec len_reg :: "'v regexp \<Rightarrow> nat" where
  "len_reg (LChr v) = 1"|
  "len_reg (ESet) = 1"|
  "len_reg \<epsilon> = 1"|
  "len_reg Dot = 1"|
  "len_reg (Concat r1 r2) = 1+ len_reg r1 + len_reg r2"|
  "len_reg (Alter r1 r2) = 1 + len_reg r1 + len_reg r2"|
  "len_reg (Star r) = 1 + len_reg r"|
  "len_reg (Plus r) = 1 + len_reg r"|
  "len_reg (Ques r) = 1 + len_reg r"

primrec trans2LTS :: "'v regexp \<Rightarrow> 'v set \<Rightarrow> ('v regexp \<times> 'v set \<times> 'v regexp) set * ('v regexp * 'v regexp) set" where 
    "trans2LTS (LChr v) alp_set= ({(LChr v, {v}, \<epsilon>)}, {})"|
    "trans2LTS (ESet) alp_set= ({}, {(ESet,\<epsilon>)})"|
    "trans2LTS (\<epsilon>) alp_set = ({}, {(\<epsilon>, \<epsilon>)})"|
    "trans2LTS (Dot) alp_set = ({(Dot, alp_set, \<epsilon>)},{})"|
    "trans2LTS (Concat r1 r2) alp_set =(renameDelta1 (fst (trans2LTS r1 alp_set)) (ConcatRegexp r2) \<union> 
                                        (fst (trans2LTS r2 alp_set)),
                                        (renameDelta2 (snd (trans2LTS r1 alp_set)) (ConcatRegexp r2) \<union> 
                                        {(Concat \<epsilon> r2, r2)}  \<union> 
                                        snd (trans2LTS r2 alp_set)))"|
    "trans2LTS (Alter r1 r2) alp_set = (fst (trans2LTS r1 alp_set) \<union> 
                                        fst (trans2LTS r2 alp_set), 
                                        snd (trans2LTS r1 alp_set) \<union> 
                                        snd (trans2LTS r2 alp_set) \<union> 
                                        {(Alter r1 r2, r1),(Alter r1 r2, r2)})"|
    "trans2LTS (Star r) alp_set = (renameDelta1 (fst (trans2LTS r alp_set)) (ConcatRegexp (Star r)), 
                                  (renameDelta2 (snd (trans2LTS r alp_set)) (ConcatRegexp (Star r))) \<union> 
                                  {(Star r, \<epsilon>),(Star r,Concat r (Star r)), (Concat \<epsilon> (Star r), Star r)})"|
    "trans2LTS (Plus r) alp_set = ((renameDelta1 (fst (trans2LTS r alp_set)) (ConcatRegexp2 (Star r))) \<union> 
                                  (renameDelta1 (fst (trans2LTS r alp_set)) (ConcatRegexp (Star r))), 
                                  {(Plus r, Concat (Concat r (Star r)) (Star r)),(Concat (Concat \<epsilon> (Star r)) (Star r),Concat (Star r) (Star r)),(Concat (Star r) (Star r), \<epsilon>), 
                                  (Concat (Star r) (Star r), Concat r (Star r)),(Concat \<epsilon> (Star r), Concat (Star r) (Star r))} \<union> 
                                  (renameDelta2 (snd (trans2LTS r alp_set)) (ConcatRegexp2 (Star r))) \<union> (renameDelta2 (snd (trans2LTS r alp_set)) (ConcatRegexp (Star r))))"|
    "trans2LTS (Ques r) alp_set = (fst (trans2LTS r alp_set), {(Ques r, \<epsilon>), (Ques r, r)} \<union> 
                                  snd (trans2LTS r alp_set))"

primrec reg2q :: "'v regexp \<Rightarrow> 'v set \<Rightarrow>  ('v regexp) set" where
    "reg2q Dot a = {Dot, \<epsilon>}"|
    "reg2q (LChr p) a =  {(LChr p), \<epsilon>}"|
    "reg2q (Alter r1 r2) a = {(Alter r1 r2)} \<union> reg2q r1 a \<union> reg2q r2 a"|
    "reg2q (Star r) a = {Star r, \<epsilon>} \<union> ConcatRegexp (Star r) ` reg2q r a" |
    "reg2q (Plus r) a = {Plus r, \<epsilon>} \<union> ConcatRegexp2 (Star r) ` reg2q r a \<union> ConcatRegexp (Star r)` reg2q r a" |
    "reg2q (Ques r) a = {(Ques r)} \<union> reg2q r a" |
    "reg2q ESet a = {ESet, \<epsilon>}" |
    "reg2q \<epsilon> a = {\<epsilon>}" |
    "reg2q (Concat r1 r2) a = ConcatRegexp r2 ` reg2q r1 a \<union> reg2q r2 a"

lemma AlterR1NotExists: "\<forall>q \<in> reg2q r1 v. (getType q = t_Alter \<and> len_reg q \<noteq> len_reg (Alter r1 r2)) \<or> getType q \<noteq> t_Alter"
    apply (induction r1 arbitrary:r2) 
    apply simp apply simp subgoal for r21 r22 r1 apply auto 
    by (smt (verit, del_insts) Suc_eq_plus1 add.commute add.left_commute len_reg.simps(6))
    subgoal for r11 r12 r2 apply auto 
    apply (metis (no_types, opaque_lifting) Suc_eq_plus1 add.assoc add.commute len_reg.simps(6))
    by (smt (verit) Suc_eq_plus1 add.assoc add.commute len_reg.simps(6))
    subgoal for r1 by auto
    subgoal for r2 r1 by auto
    subgoal for r2 r1 by auto
    subgoal for r2 r1 apply auto 
    by (metis (no_types, opaque_lifting) Suc_eq_plus1 add.assoc add.commute len_reg.simps(7))
    subgoal for r1 by auto
  done
  
lemma AlterR2NotExists: "\<forall>q \<in> reg2q r2 v. (getType q = t_Alter \<and> len_reg q \<noteq> len_reg (Alter r1 r2)) \<or> getType q \<noteq> t_Alter"
    apply (induction r2 arbitrary:r1) 
    apply simp apply simp subgoal for r21 r22 r1 apply auto 
      by (smt (verit, ccfv_SIG) Suc_eq_plus1 add.assoc add.commute len_reg.simps(6))
    subgoal for r21 r22 r1 apply auto 
      apply (smt (verit) Suc_eq_plus1 add.assoc add.commute len_reg.simps(5)) 
      by (metis add.assoc len_reg.simps(6) mult_1 mult_Suc_right)
    subgoal for r1 by auto
    subgoal for r2 r1 by auto
    subgoal for r2 r1 by auto
    subgoal for r2 r1 apply auto 
      by (metis (no_types, opaque_lifting) Suc_eq_plus1 add.assoc add.commute len_reg.simps(7))
    subgoal for r1 by auto
    done
 

lemma "Alter r1 r2 \<notin> (reg2q r1 v)"
  using AlterR1NotExists getType.simps(6) by blast

lemma "Alter r1 r2 \<notin> (reg2q r2 v)"
  using AlterR2NotExists getType.simps(6) by blast
 
fun reg2nfa :: "'v regexp \<Rightarrow> 'v set \<Rightarrow> ('v regexp,'v) NFA_rec" where 
    "reg2nfa r a= \<lparr>  \<Q> = reg2q r a,
                  \<Sigma> = alp_reg  r a,
                  \<Delta> = fst (trans2LTS r a),
                  \<Delta>' = snd (trans2LTS r a),
                  \<I> ={r}, 
                  \<F> ={\<epsilon>}\<rparr> " 

definition LQ :: "('q, 'a) NFA_rec => 'q \<Rightarrow> 'a list set" where 
 "LQ ???? q = {w. NFA_accept_Q ???? q w}"

section "function correctness of transition from regexp expression to  nondeterministic finite automaton"

lemma [simp]:"0 < len_reg r" 
  by (induct r) auto
  
theorem uniqueInitalState:"\<I> (reg2nfa r v) = {r}"
  apply (induct r)
  by auto

theorem uniqueFinalState:"\<F> (reg2nfa r v) = {\<epsilon>}"
  apply(induct r)
  by auto

 

theorem tranl_aux:
  fixes r v 
  shows "\<forall>q \<in> \<Q> (reg2nfa r v).sem_reg q v = LQ (reg2nfa r v) q"
proof(induction r)
case ESet
  then show ?case  apply(unfold LQ_def NFA_accept_Q_def ) apply auto subgoal 
      by (meson LTS_Empty LTS_Step1 singletonI) 
    prefer 2 subgoal for x 
      by (simp add: Delta1Empty)
    subgoal for x
      by (simp add: Delta1Empty)
    done
next
  case (LChr x)
  then show ?case  
    apply(unfold LQ_def NFA_accept_Q_def ) apply auto 
    subgoal for xa 
      apply(rule LTS_is_reachable.cases)  
         apply auto 
      subgoal for w 
      proof - 
        assume "LTS_is_reachable {(LChr x, {x}, ??)} {} ?? w ??" 
        then show "w = []"
          apply(rule LTS_is_reachable.cases)
            apply auto
          done
      qed
      done
    subgoal for xa          
      apply(rule LTS_is_reachable.cases)
      by auto
    done
next
  case (Concat r1 r2)
  then show ?case sorry
next
  case (Alter r1 r2)
  fix r1 r2 
  assume a1:"???q??????? (reg2nfa r1 v). sem_reg q v = LQ (reg2nfa r1 v) q"   and 
         a2:"???q??????? (reg2nfa r2 v). sem_reg q v = LQ (reg2nfa r2 v) q"
  show "???q??????? (reg2nfa (Alter r1 r2) v). sem_reg q v = LQ (reg2nfa (Alter r1 r2) v) q" 
  proof - 
  from a1 have c1:"???q??????? (reg2nfa r1 v). sem_reg q v = LQ (reg2nfa (Alter r1 r2) v) q" 
  apply (simp del: reg2nfa.simps)
  proof  
    fix q  
    assume a1:"???q??????? (reg2nfa r1 v). sem_reg q v = LQ (reg2nfa r1 v) q" and a2:"q ??? ???? (reg2nfa r1 v)"
    from a1 a2 show "LQ (reg2nfa r1 v) q = LQ (reg2nfa (Alter r1 r2) v) q" 
      apply auto 
      subgoal for x 
        proof -
        assume "x ??? LQ ??????? = reg2q r1 v, ?? = alp_reg r1 v, ?? = fst (trans2LTS r1 v), ??' = snd (trans2LTS r1 v), ??? = {r1}, ??? = {??}??? q"
        then have c1:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) q x ?? " 
          apply(unfold LQ_def NFA_accept_Q_def) by auto
        from c1 show ?thesis unfolding LQ_def NFA_accept_Q_def  apply simp
          by (metis Un_insert_right subLTSlemma)
        qed
      subgoal for x 
        proof -
          assume a1: "x ??? LQ ??????? = insert (Alter r1 r2) (reg2q r1 v ??? reg2q r2 v), ?? = alp_reg r1 v ??? alp_reg r2 v,
               ?? = fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v),
               ??' = insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v))),
               ??? = {Alter r1 r2}, ??? = {??}???  q" and a2:"q ??? reg2q r1 v"
          then have c1:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) 
                        (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) q x ??"
            apply(unfold LQ_def NFA_accept_Q_def) by auto
          from c1 a2 have "LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v))
                          (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)) q x ??"     
            sorry
          then show "x ??? LQ ??????? = reg2q r1 v, ?? = alp_reg r1 v, ?? = fst (trans2LTS r1 v), ??' = snd (trans2LTS r1 v), ??? = {r1}, ??? = {??}??? q"
            sorry
        qed
      done
  qed
  from a2 have c2:"???q??????? (reg2nfa r1 v). sem_reg q v = LQ (reg2nfa (Alter r1 r2) v) q"
    sorry
  show ?thesis sorry
qed
next
  case Dot
  then show ?case   
    apply(unfold LQ_def NFA_accept_Q_def ) 
    apply auto 
    subgoal for x 
    apply(simp add:image_iff)
    apply (rule LTS_is_reachable.cases)
    apply auto
    subgoal for a w
    proof - 
      assume "LTS_is_reachable {(Dot, v, ??)} {} ?? w ??" 
      then show "w = []"
        apply(rule LTS_is_reachable.cases)
          apply auto
        done
    qed
    done
    subgoal for x
    apply(rule LTS_is_reachable.cases)
    by auto
    done
next
  case (Star r)
  then show ?case sorry
next
  case (Plus r)
  then show ?case sorry
next
  case (Ques r)
  then show ?case sorry
next
  case ??
  then show ?case apply (unfold LQ_def NFA_accept_Q_def) 
    apply auto 
    subgoal for x 
    proof (induction x)
      case Nil
      then show ?case by auto
    next
      case (Cons a x)
      then show ?case 
      apply auto 
      apply(rule LTS_is_reachable.cases)  
      apply auto 
      by (meson Delta1Empty list.discI)
    qed      
   done    
qed


lemma transExist: "v \<noteq> {} \<Longrightarrow> \<exists>x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??"
  apply(induction r)   
  subgoal 
  proof -
    have "LTS_is_reachable {} {(ESet, ??)} ESet [] ??"
      by (meson LTS_Empty LTS_Step1 singletonI)
    then show ?thesis  by auto
  qed
  subgoal for x 
  proof - 
    have "LTS_is_reachable (fst (trans2LTS (LChr x) v)) (snd (trans2LTS (LChr x) v)) (LChr x) [x] ??" 
      by auto 
    then show ?thesis 
      by auto 
  qed
  prefer 3 subgoal proof - assume a1:"v ??? {}" have "a \<in> v \<Longrightarrow> LTS_is_reachable (fst (trans2LTS Dot v)) (snd (trans2LTS Dot v)) Dot [a] ??" by auto then show ?thesis using a1 by auto qed
  prefer 6 subgoal proof - have "LTS_is_reachable (fst (trans2LTS ?? v)) (snd (trans2LTS ?? v)) ?? [] ??" by auto then show ?thesis by auto qed
  subgoal for r1 r2 
  proof - 
    assume 1:"(v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ??)" 
    assume 2:"(v ??? {} ??? \<exists>x. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??)"
    assume 3:"v ??? {}"
    have c1:"\<exists> x. LTS_is_reachable (fst (trans2LTS (Concat r1 r2) v)) (snd (trans2LTS (Concat r1 r2) v)) (Concat r1 r2) x ??" 
    proof -
      from 1 3 have a1:"\<exists>x1. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x1 ??" by auto
      from 2 3 have a2:"\<exists>x2. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x2 ??" by auto
      from a1 have c1:"\<exists>x1.  LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)})
          ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)}) (Concat r1 r2) x1 (Concat ?? r2)"
        by (rule DeltLTSlemma2) 
      have c2:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)})
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)})) (Concat ?? r2) [] r2"
        by (meson LTS_Empty LTS_Step1 insertI1)
      from c1 have c3:"\<exists>x1. LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)})
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)})) (Concat r1 r2) x1 (Concat ?? r2)" 
        by (smt (z3) Un_commute insert_def subLTSlemma sup_idem)
      from c2 c3 have c4:"\<exists>x1. LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)})
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)})) (Concat r1 r2) x1 r2" using joinLTSlemma 
        by (metis (no_types, lifting))
      from c4 have c5:"\<exists>x1. LTS_is_reachable (fst (trans2LTS (Concat r1 r2) v)) (snd (trans2LTS (Concat r1 r2) v)) (Concat r1 r2) x1 r2" apply simp using subLTSlemma
        by fastforce
      have c6:"\<exists>x2. LTS_is_reachable (fst (trans2LTS (Concat r1 r2) v)) (snd (trans2LTS (Concat r1 r2) v)) r2 x2 ??" using a2 apply simp using subLTSlemma
        by (smt (verit, best) Un_commute Un_insert_right) 
      from c5 c6 have "\<exists>x1 x2. LTS_is_reachable (fst (trans2LTS (Concat r1 r2) v)) (snd (trans2LTS (Concat r1 r2) v)) (Concat r1 r2) (x1@x2) ??" 
        by (meson joinLTSlemma)
      then show ?thesis by auto
    qed 
    then show ?thesis by auto
  qed
  subgoal for r1 r2
  proof-
    assume a1:"(v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ??)" and a2:"(v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??)" and a3:"v ??? {}"
    from a1 a3 have c1:"???x1. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x1 ??" by auto
    from a2 a3 have c2:"???x2. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x2 ??" by auto
    have "???x1. LTS_is_reachable (fst (trans2LTS (Alter r1 r2) v)) (snd (trans2LTS (Alter r1 r2) v)) (Alter r1 r2) x1 ??" apply simp 
    proof -
    have c3:"???x1. LTS_is_reachable (fst (trans2LTS r1 v)) (insert (Alter r1 r2, r1) (snd (trans2LTS r1 v))) (Alter r1 r2) [] r1" 
      using LTS_is_reachable.simps by fastforce
    from c1 have c4:"???x1. LTS_is_reachable (fst (trans2LTS r1 v)) (insert (Alter r1 r2, r1) (snd (trans2LTS r1 v))) r1 x1 ??"
      by (metis Un_insert_right boolean_algebra_cancel.sup0 subLTSlemma)
    from c3 c4 have c5:"???x1. LTS_is_reachable (fst (trans2LTS r1 v)) (insert (Alter r1 r2, r1) (snd (trans2LTS r1 v))) (Alter r1 r2) x1 ??"
      by (meson LTS_Step1 insertI1)
    then have c6:"???x1. LTS_is_reachable (fst (trans2LTS (Alter r1 r2) v)) (snd (trans2LTS (Alter r1 r2) v)) (Alter r1 r2) x1 ??" using subLTSlemma 
      by (smt (z3) boolean_algebra_cancel.sup0 fstI insert_is_Un sndI sup_assoc sup_commute trans2LTS.simps(6))
    then show "???x1. LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) x1 ??" 
      by auto
  qed
  then show ?thesis by auto 
qed
  prefer 3
  subgoal for r 
  proof-
    assume a1:" (v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??)" and a2:"v ??? {}"
    then show "???x. LTS_is_reachable (fst (trans2LTS (Ques r) v)) (snd (trans2LTS (Ques r) v)) (Ques r) x ??"
    proof -
      from a1 a2 have c1:"???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??" by auto
      have c2:"???x. LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, ??) (insert (Ques r, r) (snd (trans2LTS r v)))) (Ques r) [] r"
        by (meson LTS_Empty LTS_Step1 insertI1 insertI2)
      have c3:"???x. LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, ??) (insert (Ques r, r) (snd (trans2LTS r v)))) r x ??"
        using c1 subLTSlemma 
        by (metis Un_empty_right Un_insert_right)
      from c3 show ?thesis 
        by (metis LTS_Empty LTS_Step1 Un_insert_left insertI1 snd_conv trans2LTS.simps(9))
    qed
  qed
  subgoal for r
  proof - assume a1:"(v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??)" and a2:"v ??? {}"
    then show "???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Star r) x ??" proof -
      from a1 a2 have c1:"???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??" by auto
      from c1 have c2:"???x. LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') ??? fst (trans2LTS r v)}
         {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') ??? snd (trans2LTS r v)} (Concat r (Star r))
         x  (Concat ?? (Star r))"
        by (rule DeltLTSlemma2)
      have c3:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Star r) [] (Concat r (Star r))" apply simp
        by (meson LTS_Empty LTS_Step1 insertI1 insertI2)
      have c4:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Concat ?? (Star r)) [] (Star r)" apply simp 
        by (metis (no_types, lifting) LTS_Empty LTS_Step1 UnI2 insertI1 insert_is_Un)
      have c5:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Star r) [] ??" apply simp
        by (meson LTS_Empty LTS_Step1 insertI1)
      have c6:"???x. LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') ??? fst (trans2LTS r v)}
         (insert (Star r, ??) (insert (Star r, Concat r (Star r)) (insert (Concat ?? (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') ??? snd (trans2LTS r v)})))
         (Concat r (Star r)) x (Concat ?? (Star r))" 
        using c2 using subLTSlemma
        by (smt (verit) Un_insert_right sup_bot.right_neutral)
      have c7:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Concat r (Star r)) x (Concat ?? (Star r))" using c6 by auto
      from c3 c7 have c8:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Star r)  x (Concat ?? (Star r))" apply auto 
        by (metis (no_types, lifting) LTS_Step1 insertI1 insert_commute)
      from c8 c4 have c9:"???x. LTS_is_reachable (fst (trans2LTS (Star r) v)) (snd (trans2LTS (Star r) v)) (Star r) x (Star r)" by auto 
      from c9 c5 show ?thesis by auto
    qed
  qed
  subgoal for r proof -
    assume a1:"(v ??? {} ??? ???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??)" and a2:"v ??? {}" 
    then show "???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Plus r) x ??" 
    proof -
      from a1 a2 have c1:"???x. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??" by auto
      have c2:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Plus r) [] (Concat (Concat r (Star r)) (Star r))" apply simp
        by (simp add: LTS_Empty LTS_Step1)
      have c3:"???x. LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') ??? fst (trans2LTS r v)})
               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') ??? snd (trans2LTS r v)})
      (Concat (Concat r (Star r)) (Star r)) x (Concat (Concat ?? (Star r)) (Star r))" using c1 by (rule DeltLTSlemma2)
      have c4:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Concat (Concat ?? (Star r)) (Star r)) []  (Concat (Star r) (Star r))" apply simp
        by (smt (verit) LTS_Empty LTS_Step1 insertI1 insert_commute)
      have c5:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Concat (Star r) (Star r)) []  ??" apply simp
        by (smt (verit) LTS_Empty LTS_Step1 UnI2 insertI1 insert_def)
      have c6:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Concat (Concat r (Star r)) (Star r)) x (Concat (Concat ?? (Star r)) (Star r))" 
        using c3 apply auto using subLTSlemma
        by (smt (verit) Un_commute Un_insert_left Un_insert_right Un_left_commute singleton_conv2)
      from c6 c3 have c7:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Plus r) x (Concat (Concat ?? (Star r)) (Star r))" apply auto
        by (meson LTS_Step1 insertI1)
      have c8:"???x. LTS_is_reachable (fst (trans2LTS (Plus r) v)) (snd (trans2LTS (Plus r) v)) (Plus r) x (Concat (Star r) (Star r))" 
          using c4 c7 by (meson joinLTSlemma1)
      show ?thesis   using c5 c8 by (meson joinLTSlemma1)
    qed
  qed
  done


theorem tranl_eq1 :
  fixes r v  
  assumes a:"v \<noteq> {}"
  shows lemma1: "sem_reg r v = \<L> (reg2nfa r v)"
  apply (rule set_eqI)
proof (induction r)
case ESet
  then show ?case apply (simp add:\<L>_def NFA_accept_def)
    by (meson Delta1Empty LTS_Empty LTS_Step1 insertI1)
next
  case (LChr x xa)
  then show ?case apply (simp add:\<L>_def NFA_accept_def)
    by (smt (verit) LTS_is_reachable.simps equals0D fst_eqD regexp.distinct(29) singleton_iff snd_eqD)
next
  case (Concat r1 r2)
  then show ?case apply (simp add:\<L>_def NFA_accept_def) apply(rule iffI)
    subgoal 
    proof -
      assume a1:" ???q p. x = q @ p ??? LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 q ?? ??? LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 p ??"
      from a1 show "LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
     (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) (Concat r1 r2) x ??" 
        apply auto
        subgoal for q p 
        proof -
          assume a2:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 q ??"
          assume a3:"LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 p ??"
          have c1:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)}) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)}) (Concat r1 r2) q (Concat ?? r2)"
            using a2 by(rule DeltLTSlemma1)
          have c2:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) (Concat r1 r2) q (Concat ?? r2)"
            using c1 by (metis (no_types, lifting) Un_insert_right subLTSlemma)
          have c3:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) (Concat ?? r2) [] r2"
            using LTS_is_reachable.simps by fastforce
          have c4:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
          (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) r2 p ??"
            using a3 by (smt (z3) Un_commute Un_insert_right subLTSlemma)
          show ?thesis using c2 c3 c4 by (smt (z3) append_Nil2 joinLTSlemma)
        qed
        done
    qed
    subgoal 
      sorry
    done
next
  case (Alter r1 r2)
  then show ?case apply (simp add:\<L>_def NFA_accept_def) apply (rule iffI) 
    subgoal 
    proof -
      assume a1:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ?? ??? LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??"
      from a1 show "LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) x ??"
        apply auto 
        subgoal 
        proof -
          assume a2:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ??"
          have c1:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) [] r1"
            using LTS_is_reachable.simps by fastforce
          have c2:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) r1 x ??" using a2
            by (metis Un_insert_right subLTSlemma)
          then show ?thesis using c1 c2 joinLTSlemma by fastforce
        qed
        subgoal
        proof -
          assume a2:"LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??"
          have c1:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) [] r2"
            using LTS_is_reachable.simps by fastforce
          have c2:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) r2 x ??" using a2
            by (smt (z3) Un_commute Un_insert_right subLTSlemma)
          then show ?thesis using c1 c2 joinLTSlemma by fastforce
        qed
        done
    qed
    subgoal
    proof (rule ccontr)
      assume a1:"?? (LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ?? ??? LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??)" and 
             a2:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) x ??"
      from a1 have c1:"?? (LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ??)" by auto  
      from a1 have c2:"?? (LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??)" by auto
      from c1 have c3:"?? (LTS_is_reachable (fst (trans2LTS r1 v)) (insert (Alter r1 r2, r1) (snd (trans2LTS r1 v))) (Alter r1 r2) x ??)" sorry
      from c2 have c4:"?? (LTS_is_reachable (fst (trans2LTS r2 v)) (insert (Alter r1 r2, r2) (snd (trans2LTS r2 v))) (Alter r1 r2) x ??)" sorry
      have c5: "??(LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) x ??)"
        sorry
      from c5 a2 show "False" by auto
      qed
    done
next
  case Dot
  then show ?case apply (simp add:\<L>_def NFA_accept_def)
    by (smt (verit) LTS_is_reachable.simps Pair_inject emptyE imageE insertI1 regexp.distinct(59) rev_image_eqI singletonD)
next
  case (Star r)
  then show ?case sorry
next
  case (Plus r)
  then show ?case sorry
next
  case (Ques r)
  then show ?case sorry
next
  case ??
  then show ?case apply (simp add:\<L>_def NFA_accept_def) 
    by (meson Delta1Empty LTS_Empty)
qed
   
theorem tranl_eq :
  fixes r v  
  assumes a:"v \<noteq> {}"
  shows lemma1: "sem_reg r v = \<L> (reg2nfa r v)"
proof(induct r)
case ESet
  then show ?case 
    apply (unfold \<L>_def NFA_accept_def)
    apply auto
    subgoal
      by (meson LTS_Empty LTS_Step1 singletonI)
    subgoal for x
      by (simp add: Delta1Empty)
    done
next
    case (LChr x)
    then show ?case     
      apply( unfold \<L>_def NFA_accept_def)
      apply auto
      apply(rule LTS_is_reachable.cases)
      apply auto
      subgoal for w
      proof -
        assume a1:"LTS_is_reachable {(LChr x, {x}, \<epsilon>)} {} (LChr x) (x # w) \<epsilon>"
        from a1 show "w = []" 
          apply(rule LTS_is_reachable.cases) apply auto
        proof -
          assume "LTS_is_reachable {(LChr x, {x}, \<epsilon>)} {} \<epsilon> w \<epsilon>"
          from this show "w = []"
            by (rule LTS_is_reachable.cases) auto
        qed
      qed 
      done
    next
  case Dot
  then show ?case 
    apply (unfold \<L>_def  NFA_accept_def)
    apply auto
    subgoal for x 
      apply(simp add:image_iff)
      apply(rule LTS_is_reachable.cases)
      apply auto
      subgoal for a w
      proof -
        assume a1:"LTS_is_reachable {(Dot, v, \<epsilon>)} {} \<epsilon> w \<epsilon>"
        from a1 have "w=[]"       
          by (rule LTS_is_reachable.cases) auto
        then show "w=[]" .
      qed
      done
    done    
next
  case \<epsilon>
  then show ?case     
    apply (unfold \<L>_def  NFA_accept_def)
    apply auto
    subgoal for x
      by (simp add: Delta1Empty)
  done
next
  case (Alter r1 r2)
  then show ?case     
    apply(unfold \<L>_def NFA_accept_def)
    apply auto
    subgoal for x
    proof -
      assume a1:"sem_reg r1 v = {w. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 w \<epsilon>}"
      assume a2:"sem_reg r2 v = {w. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 w \<epsilon>}"
      assume a3:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x \<epsilon>"
      then show "LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v)))) (Alter r1 r2) x \<epsilon>"
     proof -
        have c1:"LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v)))) (Alter r1 r2) [] r1" 
          by (metis LTS_Empty LTS_Step1 insertI1)
        from a3 have c2:"LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v)))) r1 x \<epsilon>"
          by (metis Un_insert_right subLTSlemma)
        from c1 c2 have "LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v)))) (Alter r1 r2) x \<epsilon>"
          by (metis LTS_Step1 insertI1)
        then show ?thesis by auto
      qed
    qed
     subgoal for x
      proof -
      assume a1:"sem_reg r1 v = {w. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 w \<epsilon>}"
      assume a2:"sem_reg r2 v = {w. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 w \<epsilon>}"
      assume a3:"LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x \<epsilon>"
      then show "LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v)))) (Alter r1 r2) x \<epsilon>"
      proof -
        have c1:"LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v))))  (Alter r1 r2) [] r2" 
          by (metis LTS_Empty LTS_Step1 insertI1 insertI2)
        have c2:"LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v))))  r2 x \<epsilon>"
          using a3 by (smt (z3) Un_commute Un_insert_right subLTSlemma)
        have "LTS_is_reachable (fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v))))  (Alter r1 r2) x \<epsilon>"
          using c1 c2 by (metis LTS_Step1 insertI1 insertI2)
        then show ?thesis by auto
       qed
     qed
     subgoal for x
     proof -
       assume a1:"sem_reg r1 v = {w. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 w ??}"
       assume a2:"sem_reg r2 v = {w. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 w ??}"
       assume a3:"LTS_is_reachable (fst (trans2LTS r1 v) ??? fst (trans2LTS r2 v)) (insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) ??? snd (trans2LTS r2 v)))) (Alter r1 r2) x ??"
       assume a4:"?? LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 x ??" 
       let ?trans1 = "(fst (trans2LTS r1 v) \<union> fst (trans2LTS r2 v))"
       let ?trans2 = "(insert (Alter r1 r2, r1) (insert (Alter r1 r2, r2) (snd (trans2LTS r1 v) \<union> snd (trans2LTS r2 v))))"
       show "LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 x ??"
         sorry
     qed
     done
 next
  case (Concat r1 r2)
  then show ?case 
    apply(unfold \<L>_def NFA_accept_def)
    apply auto
    subgoal for q p
    proof -
    assume a1:"sem_reg r1 v = {w. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 w \<epsilon>}"
    assume a2:"sem_reg r2 v = {w. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 w \<epsilon>}"
    assume a3:"LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 q \<epsilon>"
    assume a4:"LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 p \<epsilon>"
    show "LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
     (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) (Concat r1 r2) (q @ p) ??"
    proof-
      have c1:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)})
     ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)}) (Concat r1 r2) q (Concat \<epsilon> r2)"
        using a3  by (rule DeltLTSlemma1)
      then have c2:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)})
                    (insert (Concat \<epsilon> r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)})) (Concat r1 r2) q (Concat \<epsilon> r2)"
        using subLTSlemma 
        by (smt (verit) Un_insert_right boolean_algebra_cancel.sup0)
      then have c3:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)} \<union> fst (trans2LTS r2 v))
                    (insert (Concat \<epsilon> r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)})  \<union> snd (trans2LTS r2 v))
            (Concat r1 r2) q (Concat \<epsilon> r2)" using subLTSlemma by fastforce
      have c4:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)} \<union> fst (trans2LTS r2 v))
               (insert (Concat \<epsilon> r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)})  \<union> snd (trans2LTS r2 v)) (Concat \<epsilon> r2) [] r2"
        by (smt (z3) LTS_Empty LTS_Step1 UnI2 Un_commute insert_iff)
      have c5:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)} \<union> fst (trans2LTS r2 v))
               (insert (Concat \<epsilon> r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)})  \<union> snd (trans2LTS r2 v)) r2 p \<epsilon>"
        using a4 by (smt (z3) Un_commute subLTSlemma)
      have "LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') \<in> fst (trans2LTS r1 v)} \<union> fst (trans2LTS r2 v))
               (insert (Concat \<epsilon> r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') \<in> snd (trans2LTS r1 v)})  \<union> snd (trans2LTS r2 v)) (Concat r1 r2) (q @ p) \<epsilon>" using c3 c4 c5 
        by (smt (z3) LTS_Step1 Un_insert_left insertI1 joinLTSlemma)
      thus ?thesis by auto
    qed
  qed
  subgoal for x 
  proof -
    assume a1:"sem_reg r1 v = {w. LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 w \<epsilon>}"
    assume a2:"sem_reg r2 v = {w. LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 w \<epsilon>}"
    assume a3:"LTS_is_reachable ({(Concat q r2, va, Concat q' r2) |q va q'. (q, va, q') ??? fst (trans2LTS r1 v)} ??? fst (trans2LTS r2 v))
     (insert (Concat ?? r2, r2) ({(Concat q r2, Concat q' r2) |q q'. (q, q') ??? snd (trans2LTS r1 v)} ??? snd (trans2LTS r2 v))) (Concat r1 r2) x ??"
    show  "???q p. x = q @ p ??? LTS_is_reachable (fst (trans2LTS r1 v)) (snd (trans2LTS r1 v)) r1 q ?? ??? LTS_is_reachable (fst (trans2LTS r2 v)) (snd (trans2LTS r2 v)) r2 p ??"
      sorry
  qed
  done
next
  case (Plus r)
  then show ?case  
    apply(unfold \<L>_def NFA_accept_def)
    apply auto
    subgoal for q p
    proof -
      assume a1:"sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      assume a2:"LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r q \<epsilon>"
      assume a3:"p \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      show "LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
           {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
           (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
           (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
           ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
           {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
            (Plus r) (q @ p) \<epsilon>"
      proof -
          have c1:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                   (Plus r) [] (Concat (Concat r (Star r)) (Star r))"
            by (smt (z3) LTS_Empty LTS_Step1 insertI1)
          have e1:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}) ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})
                  (Concat (Concat r (Star r)) (Star r)) q (Concat (Concat \<epsilon> (Star r)) (Star r))"
            using a2 by (rule DeltLTSlemma1)
          have c2:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                  (Concat (Concat r (Star r)) (Star r)) q (Concat (Concat \<epsilon> (Star r)) (Star r))"
            using e1 by (smt (z3) Un_insert_right subLTSlemma) 
          have 1:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                  (Plus r) q (Concat (Concat \<epsilon> (Star r)) (Star r))"
            using c1 c2 joinLTSlemma by fastforce
          have c3:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                  (Concat (Concat \<epsilon> (Star r)) (Star r)) []  (Concat (Star r) (Star r))" 
            by (smt (verit, best) LTS_Empty LTS_Step1 insert_iff)
          have 2:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                  (Plus r) q  (Concat (Star r) (Star r))" using 1 c3 joinLTSlemma by fastforce
          have 3:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                   {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                   (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                   (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                   ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                   {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                   (Concat (Star r) (Star r)) p \<epsilon>"
                using a3 proof(induction p)
                  case zero
                  then show ?case 
                    by (smt (verit, best) LTS_Empty LTS_Step1 insert_iff snd_eqD)
                next
                  case (step x y)
                  then show ?case apply auto proof -
                    assume a1:"LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x \<epsilon>"
                    assume a2:"y \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
                    assume a3:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                               (Concat (Star r) (Star r)) y \<epsilon>"
                    have e1:"LTS_is_reachable ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}) ({(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}) (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
                      using a1 by(simp add:DeltLTSlemma1)
                    have e2:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                              (Concat (Star r) (Star r)) [] (Concat r (Star r))"
                      by (smt (verit, best) LTS_Empty LTS_Step1 insertI1 insertI2)
                   have c1:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                             (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
                     using e1 by (smt (z3) Un_insert_left subLTSlemma sup_commute) 
                    have e3:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                                  (Concat (Star r) (Star r)) x (Concat \<epsilon> (Star r))"
                      using e2 c1 joinLTSlemma by fastforce
                    have c2:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                              (Concat \<epsilon> (Star r)) [] (Concat (Star r) (Star r))" 
                      by (smt (verit, ccfv_threshold) LTS_Empty LTS_Step1 insertI1 insert_commute snd_conv)
                    have e4:"LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
                               {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                               (insert (Plus r, Concat (Concat r (Star r)) (Star r)) (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r))
                               (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r))
                               ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
                                {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
                              (Concat (Star r) (Star r)) x (Concat (Star r) (Star r))" using e3 c2 joinLTSlemma by (smt (z3) append_Nil2)
                    thus ?thesis using e4 a3 joinLTSlemma by fastforce
                  qed
                qed
              thus ?thesis using 2 3 joinLTSlemma by fastforce
        qed
     qed
    subgoal for x 
    proof -
      assume "sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      assume "LTS_is_reachable ({(Concat (Concat q (Star r)) (Star r), va, Concat (Concat q' (Star r)) (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union>
             {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}) (insert (Plus r, Concat (Concat r (Star r)) (Star r))
             (insert (Concat (Concat \<epsilon> (Star r)) (Star r), Concat (Star r) (Star r)) (insert (Concat (Star r) (Star r), \<epsilon>) (insert (Concat (Star r) (Star r), Concat r (Star r))
             (insert (Concat \<epsilon> (Star r), Concat (Star r) (Star r)) ({(Concat (Concat q (Star r)) (Star r), Concat (Concat q' (Star r)) (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)} \<union>
             {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))))))
             (Plus r) x \<epsilon>"
      show "\<exists>q p. x = q @ p \<and> LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r q \<epsilon> \<and> p \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"  
        sorry 
    qed
    done
next
  case (Star r)
  then show ?case 
     apply(unfold \<L>_def NFA_accept_def)
     apply auto 
    subgoal for x 
    proof -
      assume a1:"sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      assume a2:"x \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      show "LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}
           (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
           (Star r) x \<epsilon>" using a2 
      proof (induction x)
        case zero
        then show ?case
          by (smt (verit, best) LTS_Empty LTS_Step1 insertI1)
      next
        case (step x y)
        then show ?case apply auto 
        proof -
          assume a1:"LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x \<epsilon>"
          assume a2:"y \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
          assume a3:"LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}
                     (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                     (Star r) y \<epsilon>"
          show "LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}
                     (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                     (Star r) (x @ y) \<epsilon>"
          proof -
            have c1:"LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}
                     (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Star r) [] (Concat r (Star r))"
              by (meson LTS_Empty LTS_Step1 insertI1 insertI2)
            have c2:"LTS_is_reachable ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}) ({(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})
                    (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
              using a1 by(simp add:DeltLTSlemma1)
            have c4:"LTS_is_reachable ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union> fst (trans2LTS r v))
                    ({(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})
                    (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
              using c2 by (metis (mono_tags, lifting) Collect_cong Collect_disj_eq subLTSlemma)
            have c5:"LTS_is_reachable ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union> fst (trans2LTS r v)) 
                     ((insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)}))
                     (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
              using c4 by (smt (verit, best) Collect_cong Collect_disj_eq Un_insert_right c2 fst_eqD snd_eqD subLTSlemma)
            have c6:"LTS_is_reachable  ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)} \<union> fst (trans2LTS r v))
                    ((insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
              using c5 by (metis (no_types, lifting) Un_insert_right subLTSlemma sup_idem) 
            have c7:"LTS_is_reachable
                    ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                    (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Concat r (Star r)) x (Concat \<epsilon> (Star r))"
              by (metis (no_types, lifting) Un_absorb Un_insert_right c2 subLTSlemma)
            have c8:"LTS_is_reachable
                    ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                    (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Star r) x (Concat \<epsilon> (Star r))"
              using c1 c7 by (smt (z3) LTS_Step1 insertI1 insert_commute snd_conv)
            have c9:"LTS_is_reachable
                    ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                    (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Concat \<epsilon> (Star r)) [] (Star r)"
              by (smt (verit, best) LTS_Empty LTS_Step1 insertI1 insert_commute)
            have c10:"LTS_is_reachable
                    ({(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)})
                    (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                    (Star r) x (Star r)"
              using c8 c9 joinLTSlemma by fastforce              
            thus ?thesis using a3 c10 joinLTSlemma 
              by force 
          qed
        qed
      qed
    qed
    subgoal for x 
    proof -
      assume a1:"sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      assume a2:"LTS_is_reachable {(Concat q (Star r), va, Concat q' (Star r)) |q va q'. (q, va, q') \<in> fst (trans2LTS r v)}
                 (insert (Star r, \<epsilon>) (insert (Star r, Concat r (Star r)) (insert (Concat \<epsilon> (Star r), Star r) {(Concat q (Star r), Concat q' (Star r)) |q q'. (q, q') \<in> snd (trans2LTS r v)})))
                 (Star r) x \<epsilon>"
      show "x \<in> star {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
        sorry
    qed
    done
next
  case (Ques r)
  then show ?case     
    apply(unfold \<L>_def NFA_accept_def)
    apply auto 
    subgoal 
    proof -
      assume "sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w \<epsilon>}"
      show "LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, \<epsilon>) (insert (Ques r, r) (snd (trans2LTS r v)))) (Ques r) [] \<epsilon>"
        by (metis LTS_Empty LTS_Step1 insertI1)
    qed
    subgoal for x
    proof -
      assume a1:"sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w ??}"
      assume a2:"LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??"
      show "LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, \<epsilon>) (insert (Ques r, r) (snd (trans2LTS r v)))) (Ques r) x ??"
      proof -
        from a2 have c1:"LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, \<epsilon>) (insert (Ques r, r) (snd (trans2LTS r v)))) r x ??"
          using subLTSlemma by (metis Un_insert_right sup_bot.right_neutral)
        have "LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, \<epsilon>) (insert (Ques r, r) (snd (trans2LTS r v)))) (Ques r) x ??"
          using c1
          by (smt (verit, best) LTS_Step1 insertI1 insert_commute snd_conv)
        thus ?thesis by auto
      qed
    qed
    subgoal for x
    proof -
      assume a1:"sem_reg r v = {w. LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r w ??}"
      and a2:"LTS_is_reachable (fst (trans2LTS r v)) (insert (Ques r, \<epsilon>) (insert (Ques r, r) (snd (trans2LTS r v)))) (Ques r) x ??"
      and a3:"x ??? []" 
      show "LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??" proof (rule ccontr)
        assume a4:"?? LTS_is_reachable (fst (trans2LTS r v)) (snd (trans2LTS r v)) r x ??"
        have "?? LTS_is_reachable (fst (trans2LTS r v))  (insert (Ques r, r)  (snd (trans2LTS r v))) (Ques r) x ??" using a4 
         
          
        

   qed
end