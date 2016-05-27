#encoding "utf-8"
//IDEA: использовать словарь?
Country -> Word<gram="geo">; //Россия, Канада, ....
Country -> Adj<h-reg1, gnc-agr[1]>+ Noun<h-reg1, gnc-agr[1], rt, gram="geo">; //Российская Федерация, Саудовская Аравия
Naem -> Word<gram="persn">;
Naem -> Word<gram="famn">;
// //IDEA: h-reg3?
// Country -> Noun<h-reg2>; //США, КНДР...
Country -> Adj<h-reg1, gram="geo">+ Word<kwtype="постфикс_страна">;
Country -> Adj<h-reg1, gram="geo">+ Word<kwtype="постфикс_подрегион">;
Country -> Adj<h-reg1, gram="geo">+ Word<kwtype="постфикс_регион">;
Country -> Adj<h-reg1, gram="geo">+ Word<kwtype="префикс_регион">;
Country -> Adj<h-reg1, gram="geo">+ Word<kwtype="префикс_город">;
// Region -> Adj<h-reg1> Word<kwtype="постфикс_регион">;
// Region -> Word<kwtype="префикс_регион", gnc-agr[1]> Noun<h-reg1, gnc-agr[1]>;
// Subregion -> Adj<h-reg1> Word<kwtype="постфикс_подрегион">;
// City -> Noun<h-reg1>; // TODO: collision with Country
// City -> Word<kwtype="префикс_город", gnc-agr[1]> Noun<h-reg1, gnc-agr[1]>;
Name -> Country interp (Place.Country);
Name -> Naem interp (Name.Value);
// Place -> Region interp (Place.Region);
// Place -> Subregion interp (Place.Subregion);
// Place -> City interp (Place.City);
