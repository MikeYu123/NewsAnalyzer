#encoding "utf-8"
// Noun - не использовать
Fullname -> AnyWord<kwset="ключевые_люди">;
Some_Location -> Word<~quoted,gram="geo">+ {weight = 0.8}; //Россия, Канада, ....
Some_Location -> Adj<h-reg1, gnc-agr[1]>+ Noun<h-reg1, gnc-agr[1]>* Word<h-reg1, gnc-agr[1], gram="geo">;
Country -> Adj<h-reg1, gnc-agr[1]>+ Word<h-reg1, gnc-agr[1], rt, gram="geo">; //Российская Федерация, Саудовская Аравия
Country -> Word<kwset=["китай", "северная_корея", "россия"], h-reg1>;
Region -> Word<kwset=["московская_область"]>;
Firstname -> Word<gram="persn">;
Surname -> Word<gram="famn">;
Fullname -> Fio<kwtype="fio">;

// Country -> Word<~quoted,gram="geo,abbr">;
Subregion -> Adj<h-reg1, gnc-agr[1]> Noun<gnc-agr[1],l-reg, gram="abl",kwtype="постфикс_подрегион">;
Region -> Adj<h-reg1, gnc-agr[1]> Noun<gnc-agr[1],l-reg, gram="abl",kwtype="постфикс_регион">;
Region -> Noun<kwtype="префикс_регион",l-reg, gram="abl"> Word<h-reg1>;
Region -> (LBracket<cut>) Noun<kwtype="префикс_регион",l-reg> Word<h-reg1> (RBracket<cut>);
City ->  Noun<kwtype="префикс_город", gram="abl"> Word<h-reg1>;
// TODO: на будущее сложные паттерны, падежи и больше газеттиров
City -> Verb<kwtype="проживание",cut> (Prep<cut>) Word<h-reg1>;
Country -> (Prep) Adj<h-reg1, gnc-agr[1]>+ Word<kwtype="постфикс_страна", gnc-agr[1], h-reg1> Word<h-reg1>*;

Name -> City interp (Place.City) (Prep<cut>) Country interp(Place.Country);
Name -> Word<h-reg1> interp (Place.City) Region interp(Place.Region);
Name -> City interp (Place.City);
Name -> Region interp (Place.Region);
Name -> Subregion interp (Place.Subregion);
Name -> Country interp (Place.Country);
Name -> Some_Location interp (Place.Some_Location);
Name -> Firstname interp (Name.Firstname);
Name -> Surname interp (Name.Surname);
Name -> Fullname interp (Name.Fullname);
// Place -> Region interp (Place.Region);
// Place -> Subregion interp (Place.Subregion);
// Place -> City interp (Place.City);
