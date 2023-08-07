from pyproj import Proj

# api = Blueprint('api', __name__)

def latlon_to_utm(lat_lon):
    lat, lon = map(float, lat_lon.split('-'))
    # Calculate the UTM zone number
    zone_number = int((lon + 180) / 6) + 1
    
    # Define the Proj UTM coordinate system
    utm_proj = Proj(proj='utm', zone=zone_number, ellps='WGS84', preserve_units=False)
    
    # Convert lat/lon to UTM coordinates
    utm_easting, utm_northing = utm_proj(lon, lat)
    
    # Determine the UTM zone letter
    zone_letter = 'CDEFGHJKLMNPQRSTUVWXX'[int((lat + 80) / 8)]
    
    return f"{zone_number}{zone_letter} {utm_easting:.3f} {utm_northing:.3f}"


def utm_to_latlon(utm_str):
    # Split the input string into components
    zone, easting, northing = utm_str.split()

    # Determine the UTM zone number and hemisphere
    zone_number = int(zone[:-1])
    hemisphere = 'north' if zone[-1] >= 'N' else 'south'

    # Define the Proj UTM coordinate system
    utm_proj = Proj(proj='utm', zone=zone_number, ellps='WGS84', south=hemisphere=='south', preserve_units=False)
    
    # Convert UTM to lat/lon coordinates
    lon, lat = utm_proj(float(easting), float(northing), inverse=True)
    
    return lat, lon
