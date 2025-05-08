select c.nom, c.prenom, * from test.regularisation r inner join test.colocataire c on c.id = r.fk_colocataire where r.id = 2 ;
select t.label, l.* from test.ligne_regularisation l inner join test.type_charge t on t.id = l.fk_type_charge  where fk_regularisation = 2 ;
