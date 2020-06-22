/*
    Simpleton City Builder   minot.nut
    Simpleton class - additional functions of main class
*/

function SimpletonCB::Log(string, level = 0){
    if(level <= this.log) GSLog.Info(string);
}

/* MAP GENERATION */
function SimpletonCB::xMapgen(){
    if (GSController.GetSetting("xMapgen") == 0) {
        return;
    }

    GSLog.Info("Mapgen starts");

    local climate = GSGame.GetLandscape();

    //temperate and arctic power plants
    if(climate == 0){
        //power plant, coal
        this.PlaceIndustry(0x01, 0x01, 10, 25);
        //bank,  valuables
        this.PlaceIndustry(0x0C, 0x0A,  1, 5, true);
    }
    else if(climate == 1){
        //power plant, coal
        this.PlaceIndustry(0x01, 0x01, 10, 25);
        //bank,  valuables
        this.PlaceIndustry(0x10, 0x0A,  2, 10);
    }
    //tropic water towers
    else if(climate == 2){
        //water tower, water
        this.PlaceIndustry(0x16, 0x09,  1, 5);
        //bank,  valuables
        this.PlaceIndustry(0x10, 0x0A,  2, 10);
    }
}

function SimpletonCB::PlaceIndustry(ind, cargo, distmin, distmax, onlyCity = false) {
    local xtownlist = GSTownList();
    local txy, tx, rx, ry, ty, rtile, n, success, built = 0, skip = 0, towncount = 0, ntotal = 0, isCity;
    local tile_area = [], xtile_area = [], rand;

    //cycle industries, remove towns, where desired industry is already present
    local indlist = GSIndustryList_CargoAccepting(cargo);
    foreach(indid, _ in indlist){
        if(GSIndustry.GetIndustryType(indid) != ind) continue; //if industry is not desired, skip
         local closetownid = GSTile.GetClosestTown(GSIndustry.GetLocation(indid));
         xtownlist.RemoveItem(closetownid);
         skip++;
    }
    GSLog.Info("Mapgen will skip " + skip + " towns");
    skip = 0;

    GSCompanyMode(GSCompany.COMPANY_INVALID); //since 1.3.0 we can use GAIA company

    foreach (townid, _ in xtownlist){
        isCity = GSTown.IsCity(townid);

        //skip cities
        if ((isCity && !onlyCity) || (!isCity && onlyCity)) {
            continue;
        }
        towncount++;

        success = false;
        txy = GSTown.GetLocation(townid);
        tx = GSMap.GetTileX(txy);
        ty = GSMap.GetTileY(txy);
        n = 0;

        while (success != true && n < 127) { //try 127x or until success
            //pick random tileXY in given range
            rx = GSBase.RandRange(distmax * 2 + 1) - distmax;  
            ry = GSBase.RandRange(2 * (distmax - abs(rx)) + 1) - (distmax - abs(rx));
            if (abs(rx) + abs(ry) < distmin) {
                continue;
            }

            rtile = GSMap.GetTileIndex(tx + rx, ty + ry);
            if (!GSMap.IsValidTile(rtile) || GSRoad.IsRoadTile(rtile)) {
                //skip invalid
                continue;
            }

            success = GSIndustryType.BuildIndustry(ind, rtile); //try building here
            if (success) {
                built++;
            }
            n++;
        }

        ntotal += n;
        if(!success) {
            skip++;
        }
    }
    
    GSLog.Info("Mapgen has built " + built + " " + GSIndustryType.GetName(ind) + "s failed in " + skip + (onlyCity ? " cities" : " towns") + " of all " + towncount);
}
/* /MAP GENERATION */

/* SIGNS */
function SimpletonCB::PlaceSign(tileIndex, text) {
    local signid = GSSign.BuildSign(tileIndex, text);
    if (GSSign.IsValidSign(signid)) this.signlist.AddItem(signid, tileIndex);
    /*else{
        GSLog.Info(GSTown.GetName(GSTile.GetClosestTown(tileIndex)) + " no sign");
    }*/
}

function SimpletonCB::RemoveSign(tileIndex){
    foreach (signid, signtile in this.signlist) {
        if (signtile == tileIndex) {
            this.signlist.RemoveItem(signid);
            GSSign.RemoveSign(signid);
        }
    }
}

/*
 * The in-game coordinates *
 *         ^ Z             *
 *           |             *
 *           |             *
 *         /   \           *
 *       /       \         *
 *   X <           > Y     *
 */
function SimpletonCB::TownArea(tileIndex, companyid, place){
    if (this.townarea == 0) return;

    local locationX = GSMap.GetTileX(tileIndex);
    local locationY = GSMap.GetTileY(tileIndex);
    //get coordinates limited by map borders
    local xtop     = max(locationX - this.townarea, 1);
    local xbot     = min(locationX + this.townarea, this.mapX);
    local yleft     = max(locationY - this.townarea, 1);
    local yright = min(locationY + this.townarea, this.mapY);

    if(place){
        PlaceSign(GSMap.GetTileIndex(xtop, yleft),    GSText(GSText.STR_HQAREA_TOP, companyid));
        PlaceSign(GSMap.GetTileIndex(xbot, yright),    GSText(GSText.STR_HQAREA_BOTTOM, companyid));
        PlaceSign(GSMap.GetTileIndex(xtop, yright),    GSText(GSText.STR_HQAREA_RIGHT, companyid));
        PlaceSign(GSMap.GetTileIndex(xbot, yleft),    GSText(GSText.STR_HQAREA_LEFT, companyid));
    }
    else{
        RemoveSign(GSMap.GetTileIndex(xtop, yleft));
        RemoveSign(GSMap.GetTileIndex(xtop, yright));
        RemoveSign(GSMap.GetTileIndex(xbot, yright));
        RemoveSign(GSMap.GetTileIndex(xbot, yleft));
    }
}
/* /SIGNS */