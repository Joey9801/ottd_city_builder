/*
    Simpleton City Builder   town.nut
    Town class - town pool of claimed towns
*/

class Town
{
    id = INVALID_TOWN;
    owner = INVALID_COMPANY;
    city = null;
    growing = false; //is town growing?
    grow_counter = 320; //when <0 build a house
    delta = 0; //date of last growth check, updates grow_counter
    nameid = 0; //town string name
    president = ""; //president name for change name check
    storage =   [];
    delivered = [];
    missing = 0; //mask of missing cargos
    service = false; //has town transport service?
    
    notgrowinrow = 0; //consecutive months when town did not grew
    growinrow = 0; //consecutive months when town did grew
    growtotal = 0; //total months when town did grew
    monthstotal = 0; //total months in game
    prevgrowed = false; //did town grew last month?
    funddur = 0;  //duratio nof funding buildings
    fundedtotal = 0; //total funded months

    constructor(id, owner, city = null){
        this.id = id;
        this.owner = owner;
        this.city = city;
        this.delta = GSDate.GetCurrentDate();
        this.nameid = 0;
        this.president = "";
        this.storage =   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //32x
        this.delivered = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //32x

        this.missing = 0;
        this.service = false;
        this.grow_counter = 320;
        this.growing = false;
        this.notgrowinrow = 0;
        this.growinrow = 0;
        this.growtotal = 0;
        this.monthstotal = 0;
        this.prevgrowed = false;
        this.funddur = 0;
        this.fundedtotal = 0;
    }

    function Grow(growmech);
    function Loc();
    function ServicedStationCount();
}

function Town::Grow(growmech){
    this.monthstotal++;
    this.funddur = GSTown.GetFundBuildingsDuration(this.id);
    
    if(!this.growing){
        if(this.prevgrowed){
            GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
        }
        this.grow_counter = 0;
        this.notgrowinrow++;
        this.growinrow = 0;
        this.prevgrowed = false;
        return 0;
    }
    
    this.notgrowinrow = 0;
    this.growinrow++;
    this.growtotal++;

    if(this.funddur > 0) this.fundedtotal++;

    if(growmech == Growth.GROW_NORMAL){
        if(!this.prevgrowed){
            GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NORMAL);
            this.grow_counter = 0;
        }
        this.prevgrowed = true;
        return GSTown.GetGrowthRate(this.id);
    }
    
    if(growmech == Growth.GROW_EXPAND){
        // Try to get close to OpenTTD native grow mechanics
        local service = this.ServicedStationCount(); 

        local growrate = GSGameSettings.GetValue("economy.town_growth_rate");
        local funded = this.funddur > 0 ? 0 : 1;
        local grow_values = [
            [120, 120, 120, 100,  80,  60],  //with fund buildings
            [320, 420, 300, 220, 160, 100]   //normal growth
        ];
        
        local grow_value = grow_values[funded][min(service, 5)];

        if (service == 0 && !((GSBase.RandRange(12)+1)/12) == 1) return 0;
        growrate = (growrate != 0) ? (growrate - 1) : 1;
        growrate = grow_value >> growrate;
        growrate /= (GSTown.GetHouseCount(this.id) / 50 + 1);
        if(growrate == 0) growrate++;
        GSTown.SetGrowthRate(this.id, growrate);
        if(this.grow_counter > growrate) this.grow_counter = growrate;
        this.prevgrowed = true;
        return growrate;
    }
}

function Town::Loc() {
    return GSTown.GetLocation(this.id);
}

/// Returns the count of stations that are being serviced in this town, capped at 5
function Town::ServicedStationCount(){
    // Set of filters on stations.
    // Each filters has the signature (station id) -> bool, returning true if the station passes the filter
    // A station must pass all filters to be considered serviced
    local station_filters = [
        // Is this a valid station at all
        GSStation.IsValidStation,

        // Is it owned by the correct player
        function (stid) { return GSStation.GetOwner(stdid) == this.owner },

        // Is is close enough to the center of this town
        function (stid) { return GSStation.GetDistanceManhattanToTile(stid, this.Loc()) < 20 },

        // Is there at least one active vehicle there
        function (stid) {
            foreach (vehicle_id, _ in GSVehicleList_Station(stid)) {
                local vehicle_state = GSVehicle.GetState(vehicle_id);
                if (vehicle_state == GSVehicle.VS_RUNNING || vehicle_state.GSVehicle.VS_AT_STATION) {
                    return true;
                }
            }
            return false;
        }
    ]

    // Running count of serviced stations
    local serviced_station_count = 0;

    // Iterate through every station in the world
    foreach (station_id, _ in GSStationList(GsStation.STATION_ANY)) {
        // If all the filters pass, this is a serviced station
        if (all(station_filters, function(filter) { return filter(stid); })) {
            serviced_station_count += 1;
        }

        if (serviced_station_count >= 5) {
            // No need to count further than this
            break;
        } 
    }

    return serviced_station_count;
}

function all(arr, predicate) {
    foreach (value in arr) {
        if (!predicate(value)) {
            return false;
        }
    }

    return true;
}