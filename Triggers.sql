use GestionCom

--  1-	Créer un trigger qui  interdit la modification des commandes 
create trigger tr_Commande_insteadOfUpdate
on Commande
instead of Update
as
begin
   Raiserror('tu peux pas modifier',16,1)
end
update Commande set dateCom=getdate() where numCom=1

-- 2-	Créer un trigger qui à l'ajout d'une ligne de commande vérifie si les quantités sont 
-- disponibles et met le stock à jour

create trigger tr_LigneCommande_isteadOfInsert
on LigneCommande
for Insert
as
begin
  --recuperer les info de ligne commande insere
  declare @numArticle int
  declare @qCommandee int
  select @qCommandee=qteCommandee,@numArticle=numArt from inserted
  
  --recuperer la quantite en stock d'article
  declare @qEnStock int
  select @qEnStock=qtEenStock from Article where numArt=@numArticle

  -- si la quantite commandee supperieur de la quantite en stock on affiche un error
  if (@qCommandee>@qEnStock)
    begin
	   Raiserror('quantite insuffisant',16,1)
	   Rollback
	   return
	end
  -- mise a jour la quantite en stock
  update Article set qtEenStock=(qtEenStock-@qCommandee) 
  where numArt=@numArticle
end
Select * from Commande 
Select * from Article
Select * from LigneCommande
insert into LigneCommande values(12,2,1)

select * from Article
select * from Commande
select * from LigneCommande

-- 3-	Créer un trigger qui à la modification d'une ligne de commande 
--  vérifie si les quantités sont disponibles et met le stock à jour
alter trigger tr_LigneCommande_InstedOfUpdate
on LigneCommande
for Update
as
begin
  declare @qttDisponible int
  declare @NewQttCommandee int
  declare @OldQttCommandee int
  declare @numArt int

  select @NewQttCommandee=qteCommandee,@numArt=numArt from inserted
  select @OldQttCommandee=qteCommandee from deleted
  select @qttDisponible=qtEenStock from Article where numArt=@numArt

  if(@NewQttCommandee>@OldQttCommandee)
    begin
	  declare @QttCommandee int
	  set @QttCommandee=@NewQttCommandee-@OldQttCommandee
	  if(@qttDisponible<@QttCommandee)
	    begin
	      RaisError('La quantite pas disponible',16,1)
	  	  Rollback
		  return
	    end
      else
	    begin
		  update Article set qtEenStock=qtEenStock-@QttCommandee where numArt=@numArt
		end
	end
  else
    begin
	  declare @QttDeCommandee int
	  set @QttDeCommandee=@OldQttCommandee-@NewQttCommandee
	  Update Article set qtEenStock=qtEenStock+@QttDeCommandee where numArt=@numArt
	end
end

select * from LigneCommande
select * from Article
insert into LigneCommande values(1,1,1)
update LigneCommande set qteCommandee=3
where numArt=1 and numCom=1


-- 4-	Créer un trigger qui interdit l’augmentation du stock d’un article 
-- si le seuil maximal de cet article est atteint.
create trigger tr_Article_AfterOfUpdate
on Article 
for update 
as 
begin
  declare @NewQtt int
  declare @SeuilMax int
  select @NewQtt=qtEenStock,@SeuilMax=seuilMaximum from inserted
  if(@NewQtt>@SeuilMax)
    begin
	  RaisError('le seuil maximal de cet article est atteint.',16,1)
	  Rollback
	  return
	end
end
update Article set qtEenStock=100 where numArt=1

--5-	Créer un trigger qui affiche un message d’approvisionnement après l’ajout d’une ligne 
-- de commande si le seuil minimum est atteint pour l’article commandé.

create trigger tr_LigneCommande_ForInsert
on LigneCommande
for insert
as
begin
  declare @numArticle int
  declare @qCommandee int
  select @qCommandee=qteCommandee,@numArticle=numArt from inserted
  
  --recuperer le seuil minimal et la qtt en stock d'article
  declare @SMin int
  declare @QttEnStock int
  select @SMin=seuilMinimum,@QttEnStock=qtEenStock from Article where numArt=@numArticle

  declare @DisQtt int
  set @DisQtt = @QttEnStock - @qCommandee
  -- si le seuil minimum est atteint pour l’article commandé on affiche un message
  if (@DisQtt< @SMin)
    begin
	  print 'le seuil minimum est atteint pour l’article commandé' 
	end
end
