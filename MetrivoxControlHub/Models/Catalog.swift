import Foundation

enum ProfessionCatalog {
    static var schemes: [CatalogScheme] { interior + brand + shoot }

    static func schemes(for trade: TradeKind) -> [CatalogScheme] {
        schemes.filter { $0.trade == trade }
    }

    static func scheme(id: String) -> CatalogScheme? {
        schemes.first { $0.id == id }
    }

    private static let interior: [CatalogScheme] = [
        CatalogScheme(
            id: "int-north-living",
            name: "North Living Plaster",
            trade: .interior,
            useWhen: "North-facing living room. Read wall next to oak and linen, not as a chip on a phone.",
            lightNote: "Clear window light, cool bias on plaster.",
            interiorLight: .daylight,
            pairs: [("Wall", "#C9C3B8"), ("Trim", "#F4F1EA"), ("Floor", "#B08968"), ("Ceiling", "#F7F4EE"), ("Textile", "#D9C7A8")]
        ),
        CatalogScheme(
            id: "int-lamp-bedroom",
            name: "Lamp Bedroom Clay",
            trade: .interior,
            useWhen: "Bedroom seen at night. Clay wall will go orange under 2700K — check trim before paint.",
            lightNote: "Warm bedside lamps on plaster.",
            interiorLight: .warmLamp,
            pairs: [("Wall", "#C4A484"), ("Trim", "#EFE6D9"), ("Floor", "#6E4B32"), ("Ceiling", "#F3EBDF"), ("Textile", "#8C3B3B")]
        ),
        CatalogScheme(
            id: "int-overcast-kitchen",
            name: "Overcast Kitchen Sage",
            trade: .interior,
            useWhen: "Galley kitchen with one window. Sage dies in gray weather; keep floor warm so the room does not go olive.",
            lightNote: "Overcast, low chroma.",
            interiorLight: .overcast,
            pairs: [("Wall", "#9AA78A"), ("Trim", "#F2EEE6"), ("Floor", "#D8C3A5"), ("Ceiling", "#FAF7F1"), ("Textile", "#6F7A63")]
        ),
        CatalogScheme(
            id: "int-cool-bath",
            name: "Powder Cool Tile",
            trade: .interior,
            useWhen: "Small bath with 4000K LEDs. Avoid yellow stone; cool tile plus warm wood vanity.",
            lightNote: "Cool lamp, high reflectance.",
            interiorLight: .coolLamp,
            pairs: [("Wall", "#D5DDE2"), ("Trim", "#F7F7F4"), ("Floor", "#8A8F93"), ("Ceiling", "#FBFBFA"), ("Textile", "#C9A07A")]
        ),
        CatalogScheme(
            id: "int-hallway-oak",
            name: "Hallway Oak Wrap",
            trade: .interior,
            useWhen: "Narrow hall with no direct sun. Floor carries warmth; wall stays quiet so doors read.",
            lightNote: "Daylight from the far end only.",
            interiorLight: .daylight,
            pairs: [("Wall", "#E4DDD2"), ("Trim", "#F8F4EC"), ("Floor", "#A56B3C"), ("Ceiling", "#F6F2EA"), ("Textile", "#5A4638")]
        ),
        CatalogScheme(
            id: "int-library-green",
            name: "Study Green Library",
            trade: .interior,
            useWhen: "Desk room with a lamp. Deep green wall, pale ceiling, leather chair — not a complementary wheel.",
            lightNote: "Warm lamp against dark plaster.",
            interiorLight: .warmLamp,
            pairs: [("Wall", "#355E4B"), ("Trim", "#E8DCC8"), ("Floor", "#5C4033"), ("Ceiling", "#F0E6D4"), ("Textile", "#8B3A2A")]
        ),
        CatalogScheme(
            id: "int-coastal-sit",
            name: "Coastal Sitting Room",
            trade: .interior,
            useWhen: "Seaside cottage. Blue-gray wall next to bleached floor; textile is sand, not navy.",
            lightNote: "Bright daylight, slight cool.",
            interiorLight: .daylight,
            pairs: [("Wall", "#B7C4C9"), ("Trim", "#F8F6F1"), ("Floor", "#D7C4A3"), ("Ceiling", "#FBF9F4"), ("Textile", "#E6D5B8")]
        ),
        CatalogScheme(
            id: "int-loft-concrete",
            name: "City Loft Concrete",
            trade: .interior,
            useWhen: "Open loft. Concrete wall, black metal trim, pale oak. Overcast keeps it from going beige.",
            lightNote: "Overcast city light.",
            interiorLight: .overcast,
            pairs: [("Wall", "#8E8C89"), ("Trim", "#1F1F1F"), ("Floor", "#D2B48C"), ("Ceiling", "#E8E4DE"), ("Textile", "#5C1A1A")]
        ),
        CatalogScheme(
            id: "int-nursery-clay",
            name: "Nursery Soft Clay",
            trade: .interior,
            useWhen: "Child room. Clay wall stays calm under warm night light; floor is cork, not gray vinyl.",
            lightNote: "Warm lamp after dark.",
            interiorLight: .warmLamp,
            pairs: [("Wall", "#E2C8B0"), ("Trim", "#F7F1E8"), ("Floor", "#C4A574"), ("Ceiling", "#FBF6EE"), ("Textile", "#8FA58A")]
        ),
        CatalogScheme(
            id: "int-dining-wine",
            name: "Dining Wine Niche",
            trade: .interior,
            useWhen: "Dining alcove. Wine wall only if ceiling is cream and floor is walnut — otherwise it reads as a bar.",
            lightNote: "Warm pendant over table.",
            interiorLight: .warmLamp,
            pairs: [("Wall", "#6B2B3A"), ("Trim", "#EFE4D4"), ("Floor", "#5A3A28"), ("Ceiling", "#F3E8D8"), ("Textile", "#C9A24A")]
        ),
        CatalogScheme(
            id: "int-spa-stone",
            name: "Spa Bath Stone",
            trade: .interior,
            useWhen: "Spa bath. Stone wall, cooler LEDs, teak bench. Do not add a mint accent.",
            lightNote: "Cool lamp on wet stone.",
            interiorLight: .coolLamp,
            pairs: [("Wall", "#C5BDB3"), ("Trim", "#F4F0EA"), ("Floor", "#9B8E82"), ("Ceiling", "#F7F5F1"), ("Textile", "#A67B5B")]
        ),
        CatalogScheme(
            id: "int-attic-white",
            name: "Attic Studio White",
            trade: .interior,
            useWhen: "Sloped studio. White wall is never pure white next to pine floor; trim is the same family, one step cooler.",
            lightNote: "Daylight from a dormer.",
            interiorLight: .daylight,
            pairs: [("Wall", "#F3EFE8"), ("Trim", "#E7E2D8"), ("Floor", "#C8A882"), ("Ceiling", "#FAF7F2"), ("Textile", "#6B7C8A")]
        ),
        CatalogScheme(
            id: "int-entry-charcoal",
            name: "Entry Charcoal Wrap",
            trade: .interior,
            useWhen: "Entry that must hide dirt. Charcoal wall, pale stone floor, brass textile. Daylight from the door only.",
            lightNote: "Daylight from the street door.",
            interiorLight: .daylight,
            pairs: [("Wall", "#3A3F44"), ("Trim", "#E6DFD4"), ("Floor", "#D4C8B8"), ("Ceiling", "#EFEAE2"), ("Textile", "#B08D57")]
        ),
        CatalogScheme(
            id: "int-sunroom-straw",
            name: "Sunroom Straw",
            trade: .interior,
            useWhen: "Glass sunroom. Straw wall burns at noon; keep ceiling cooler and floor terracotta.",
            lightNote: "Hard daylight.",
            interiorLight: .daylight,
            pairs: [("Wall", "#E6D5A8"), ("Trim", "#F8F3E6"), ("Floor", "#C4784A"), ("Ceiling", "#F3F0E8"), ("Textile", "#6A8F71")]
        ),
        CatalogScheme(
            id: "int-guest-putty",
            name: "Guest Suite Putty",
            trade: .interior,
            useWhen: "Guest suite with mixed lamps. Putty wall, white trim, gray-wash floor. Cloud light is the honest read.",
            lightNote: "Overcast, hotel-quiet.",
            interiorLight: .overcast,
            pairs: [("Wall", "#D8D0C5"), ("Trim", "#F5F2EC"), ("Floor", "#B7AFA4"), ("Ceiling", "#F8F6F1"), ("Textile", "#7A5C58")]
        ),
        CatalogScheme(
            id: "int-mudroom-olive",
            name: "Mudroom Olive",
            trade: .interior,
            useWhen: "Mudroom. Olive wall hides coats; tile floor, cream ceiling. Cool lamp so olive does not go brown.",
            lightNote: "Cool utility LEDs.",
            interiorLight: .coolLamp,
            pairs: [("Wall", "#6E6B4F"), ("Trim", "#EFE8DA"), ("Floor", "#8A8478"), ("Ceiling", "#F4EEE4"), ("Textile", "#4A3728")]
        ),
        CatalogScheme(
            id: "int-lounge-ink",
            name: "Evening Lounge Ink",
            trade: .interior,
            useWhen: "Evening lounge. Ink wall only with warm lamp and a pale textile so faces do not disappear.",
            lightNote: "Warm lamp, low wall reflectance.",
            interiorLight: .warmLamp,
            pairs: [("Wall", "#1E2430"), ("Trim", "#D9CDB8"), ("Floor", "#4A3728"), ("Ceiling", "#2A3140"), ("Textile", "#C4A882")]
        ),
        CatalogScheme(
            id: "int-island-navy",
            name: "Kitchen Island Navy",
            trade: .interior,
            useWhen: "Island run. Navy cabinetry as wall, maple floor, white ceiling. Cool under-cabinet light on the worktop.",
            lightNote: "Cool task LEDs on the island.",
            interiorLight: .coolLamp,
            pairs: [("Wall", "#1F3358"), ("Trim", "#F4F0E8"), ("Floor", "#C9A06A"), ("Ceiling", "#F8F5EF"), ("Textile", "#B5523A")]
        )
    ]

    private static let brand: [CatalogScheme] = [
        CatalogScheme(
            id: "br-clinic-teal",
            name: "Clinic Paper Teal",
            trade: .brand,
            useWhen: "Clinic mark on paper. Teal mark, bone field, charcoal type. Never drop the mark on yellow.",
            lightNote: "Print on uncoated stock.",
            pairs: [("Mark", "#0F7A7A"), ("Field", "#F4EFE6"), ("Type", "#2B2B2B"), ("Support", "#8FA8A8"), ("Clash", "#F0C400")]
        ),
        CatalogScheme(
            id: "br-cafe-espresso",
            name: "Night Cafe Espresso",
            trade: .brand,
            useWhen: "Cafe after dark. Cream mark on espresso field. Clash is neon lime menus.",
            lightNote: "Mark on dark board, not on a screen white.",
            pairs: [("Mark", "#F3E6D0"), ("Field", "#2A1A12"), ("Type", "#F7F1E6"), ("Support", "#A36A3A"), ("Clash", "#B6FF3A")]
        ),
        CatalogScheme(
            id: "br-school-cobalt",
            name: "School Kit Cobalt",
            trade: .brand,
            useWhen: "School kit. Cobalt mark, white field, navy type. Forbidden: mark on red sports jersey.",
            lightNote: "Offset print, coated cover.",
            pairs: [("Mark", "#1E4DB7"), ("Field", "#F7F7F7"), ("Type", "#14233D"), ("Support", "#F2C14E"), ("Clash", "#D12121")]
        ),
        CatalogScheme(
            id: "br-baker-cream",
            name: "Baker Cream Stamp",
            trade: .brand,
            useWhen: "Bakery stamp. Cocoa mark on cream. Clash is dusty pink boxes that kill the cocoa.",
            lightNote: "Kraft and cream labels.",
            pairs: [("Mark", "#6B3F2A"), ("Field", "#F6EBD8"), ("Type", "#3A2618"), ("Support", "#C9A06A"), ("Clash", "#E8A8B8")]
        ),
        CatalogScheme(
            id: "br-legal-navy",
            name: "Legal Navy Bond",
            trade: .brand,
            useWhen: "Legal letterhead. Navy mark, bond field. Clash is teal “friendly” folders.",
            lightNote: "Bond paper, black text.",
            pairs: [("Mark", "#1A2852"), ("Field", "#F5F2EA"), ("Type", "#1A1A1A"), ("Support", "#8A7A62"), ("Clash", "#2A9B8A")]
        ),
        CatalogScheme(
            id: "br-coop-leaf",
            name: "Outdoor Co-op Leaf",
            trade: .brand,
            useWhen: "Outdoor co-op. Leaf mark on sand field. Clash is hunter-camo that swallows the leaf.",
            lightNote: "Vehicle wrap and paper bags.",
            pairs: [("Mark", "#3F6B3A"), ("Field", "#EFE6D4"), ("Type", "#24301F"), ("Support", "#C4A882"), ("Clash", "#2F4A28")]
        ),
        CatalogScheme(
            id: "br-radio-violet",
            name: "Night Radio Violet",
            trade: .brand,
            useWhen: "Night radio. Violet mark on ink field. Clash is hot magenta that fights the mark.",
            lightNote: "Dark UI and stickers.",
            pairs: [("Mark", "#8A4CFF"), ("Field", "#12081C"), ("Type", "#F4EEFF"), ("Support", "#5C1A6E"), ("Clash", "#E827CB")]
        ),
        CatalogScheme(
            id: "br-kids-block",
            name: "Kids Block Primary",
            trade: .brand,
            useWhen: "Kids line. Red mark on cream. Clash is electric cyan toys next to the mark.",
            lightNote: "Soft goods and boxes.",
            pairs: [("Mark", "#D62828"), ("Field", "#FFF6E8"), ("Type", "#1F1F1F"), ("Support", "#F4B400"), ("Clash", "#00D4FF")]
        ),
        CatalogScheme(
            id: "br-hotel-linen",
            name: "Hotel Linen Gold",
            trade: .brand,
            useWhen: "Hotel linen. Gold mark on ivory. Clash is black-tie navy that turns gold cheap.",
            lightNote: "Embossed paper and towels.",
            pairs: [("Mark", "#B08D57"), ("Field", "#F7F1E6"), ("Type", "#3A3228"), ("Support", "#D9C7A8"), ("Clash", "#1A2852")]
        ),
        CatalogScheme(
            id: "br-bike-steel",
            name: "Bike Shop Steel",
            trade: .brand,
            useWhen: "Bike shop. Steel mark on ash field. Clash is safety orange that overpowers the steel.",
            lightNote: "Metal signage and receipts.",
            pairs: [("Mark", "#5A6570"), ("Field", "#E6E2DC"), ("Type", "#1C1C1C"), ("Support", "#C45C26"), ("Clash", "#FF6A00")]
        ),
        CatalogScheme(
            id: "br-florist-blush",
            name: "Florist Blush",
            trade: .brand,
            useWhen: "Florist. Blush mark on pale field. Clash is supermarket green wrap.",
            lightNote: "Tissue and window vinyl.",
            pairs: [("Mark", "#D989A0"), ("Field", "#FBF4F0"), ("Type", "#4A2C34"), ("Support", "#E8C9A0"), ("Clash", "#3D8B3D")]
        ),
        CatalogScheme(
            id: "br-hardware-ochre",
            name: "Hardware Ochre",
            trade: .brand,
            useWhen: "Hardware co. Ochre mark on putty. Clash is big-box blue.",
            lightNote: "Aprons and aisle cards.",
            pairs: [("Mark", "#C4781A"), ("Field", "#E8E0D4"), ("Type", "#2A241C"), ("Support", "#6E5A44"), ("Clash", "#0057B8")]
        ),
        CatalogScheme(
            id: "br-gallery-white",
            name: "Gallery White Frame",
            trade: .brand,
            useWhen: "Gallery. Black mark on white. Clash is warm gallery cream that dirties the frame.",
            lightNote: "Wall labels and invites.",
            pairs: [("Mark", "#111111"), ("Field", "#FFFFFF"), ("Type", "#111111"), ("Support", "#C0C0C0"), ("Clash", "#EDE4D4")]
        ),
        CatalogScheme(
            id: "br-distillery-amber",
            name: "Distillery Amber",
            trade: .brand,
            useWhen: "Distillery. Amber mark on charcoal. Clash is whiskey-stock gold foil everywhere.",
            lightNote: "Bottle neck and cases.",
            pairs: [("Mark", "#C47A22"), ("Field", "#2B2B2B"), ("Type", "#F4EBD8"), ("Support", "#8A5A2B"), ("Clash", "#E0B84A")]
        ),
        CatalogScheme(
            id: "br-ferry-navy",
            name: "Ferry Line Navy",
            trade: .brand,
            useWhen: "Ferry line. White mark on navy. Clash is tourist cyan.",
            lightNote: "Hull paint and tickets.",
            pairs: [("Mark", "#F4F4F4"), ("Field", "#12305A"), ("Type", "#F4F4F4"), ("Support", "#C45C3A"), ("Clash", "#19C6E8")]
        ),
        CatalogScheme(
            id: "br-yoga-sand",
            name: "Yoga Shala Sand",
            trade: .brand,
            useWhen: "Yoga shala. Clay mark on sand. Clash is neon studio purple.",
            lightNote: "Mats and window letters.",
            pairs: [("Mark", "#A56B4A"), ("Field", "#F3E6D4"), ("Type", "#3A2A20"), ("Support", "#C9B8A0"), ("Clash", "#7A3CFF")]
        ),
        CatalogScheme(
            id: "br-jazz-crimson",
            name: "Jazz Club Crimson",
            trade: .brand,
            useWhen: "Jazz club. Crimson mark on ink. Clash is poster yellow.",
            lightNote: "Door card and vinyl.",
            pairs: [("Mark", "#9B1B30"), ("Field", "#12080C"), ("Type", "#F4E8D8"), ("Support", "#C9A24A"), ("Clash", "#FFE14A")]
        ),
        CatalogScheme(
            id: "br-arch-graphite",
            name: "Arch Studio Graphite",
            trade: .brand,
            useWhen: "Architecture studio. Graphite mark on vellum. Clash is teal CAD screenshots as a field.",
            lightNote: "Trace paper and site boards.",
            pairs: [("Mark", "#4A4A4A"), ("Field", "#EFECE6"), ("Type", "#1A1A1A"), ("Support", "#8A847C"), ("Clash", "#1AA6A6")]
        )
    ]

    private static let shoot: [CatalogScheme] = [
        CatalogScheme(
            id: "sh-interview-gray",
            name: "Daylight Interview Gray",
            trade: .shoot,
            useWhen: "Talking-head interview. Gray key, navy fill, charcoal cyc. Wardrobe not in the key.",
            lightNote: "5600K key, cool fill.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#C5C8CC"), ("Fill", "#1F3358"), ("Backdrop", "#3A3F44"), ("Wardrobe", "#6B2B3A"), ("Practical", "#E8DCC8")]
        ),
        CatalogScheme(
            id: "sh-tungsten-kitchen",
            name: "Tungsten Kitchen Talk",
            trade: .shoot,
            useWhen: "Kitchen sit-down. 3200K. Warm practicals, cream wardrobe, dark backsplash as backdrop.",
            lightNote: "Tungsten, practicals on.",
            shootLight: .kelvin3200,
            pairs: [("Key", "#E8C9A0"), ("Fill", "#8A5A2B"), ("Backdrop", "#3A2A22"), ("Wardrobe", "#F3E6D0"), ("Practical", "#FFB060")]
        ),
        CatalogScheme(
            id: "sh-shade-portrait",
            name: "Open Shade Portrait",
            trade: .shoot,
            useWhen: "Portrait in open shade. Cooler key, soft fill, green-not-as-backdrop. Wardrobe with warmth.",
            lightNote: "Open shade, no sun on face.",
            shootLight: .openShade,
            pairs: [("Key", "#B8C6D4"), ("Fill", "#D9C7A8"), ("Backdrop", "#6E6B4F"), ("Wardrobe", "#8C3B3B"), ("Practical", "#F4EBD8")]
        ),
        CatalogScheme(
            id: "sh-mixed-bar",
            name: "Mixed Practical Bar",
            trade: .shoot,
            useWhen: "Bar scene. Window is cool, practicals are tungsten. Wardrobe cannot match the gel.",
            lightNote: "Mixed: warm practical vs cool window.",
            shootLight: .mixed,
            pairs: [("Key", "#E6B07A"), ("Fill", "#8AA8C4"), ("Backdrop", "#1E2430"), ("Wardrobe", "#C9A06A"), ("Practical", "#FF8C40")]
        ),
        CatalogScheme(
            id: "sh-product-white",
            name: "Product White Table",
            trade: .shoot,
            useWhen: "Tabletop product. White key, gray fill, white sweep. Wardrobe N/A — use support card as wardrobe chip.",
            lightNote: "5600K, no mixed lamps.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#F4F4F4"), ("Fill", "#B0B4B8"), ("Backdrop", "#E8E8E8"), ("Wardrobe", "#2B2B2B"), ("Practical", "#FFFFFF")]
        ),
        CatalogScheme(
            id: "sh-fashion-cyc",
            name: "Fashion Cool Cyc",
            trade: .shoot,
            useWhen: "Fashion on cyc. Cool key, magenta gel practical, charcoal wardrobe.",
            lightNote: "5600K key, gel as practical.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#DCE6F0"), ("Fill", "#8A4C78"), ("Backdrop", "#E4E0DC"), ("Wardrobe", "#2B2B2B"), ("Practical", "#E827CB")]
        ),
        CatalogScheme(
            id: "sh-doc-overcast",
            name: "Doc Handheld Overcast",
            trade: .shoot,
            useWhen: "Doc handheld. Overcast street. Gray key, brick backdrop, no shiny wardrobe.",
            lightNote: "Open shade / overcast.",
            shootLight: .openShade,
            pairs: [("Key", "#C8C2BA"), ("Fill", "#7A6A5A"), ("Backdrop", "#8A4A32"), ("Wardrobe", "#3A3F44"), ("Practical", "#D9C7A8")]
        ),
        CatalogScheme(
            id: "sh-night-avoid-sodium",
            name: "Night Exterior Sodium-Avoid",
            trade: .shoot,
            useWhen: "Night street. Avoid sodium-orange wardrobe. Cool fill, warm practical window only.",
            lightNote: "Mixed night: cool street vs warm window.",
            shootLight: .mixed,
            pairs: [("Key", "#6A7A8A"), ("Fill", "#2A3444"), ("Backdrop", "#121820"), ("Wardrobe", "#1F3358"), ("Practical", "#E8A050")]
        ),
        CatalogScheme(
            id: "sh-talk-navy",
            name: "Talking Head Navy",
            trade: .shoot,
            useWhen: "Corporate talking head. Navy backdrop, gray key, burgundy wardrobe — not matching the cyc.",
            lightNote: "5600K, even key.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#D0D4D8"), ("Fill", "#5A6570"), ("Backdrop", "#1A2852"), ("Wardrobe", "#6B2B3A"), ("Practical", "#F4EBD8")]
        ),
        CatalogScheme(
            id: "sh-food-3200",
            name: "Food Overhead 3200",
            trade: .shoot,
            useWhen: "Food overhead. 3200K so butter reads. Dark backdrop, no blue wardrobe in frame.",
            lightNote: "Tungsten overhead.",
            shootLight: .kelvin3200,
            pairs: [("Key", "#F0D2A8"), ("Fill", "#A36A3A"), ("Backdrop", "#2A1A12"), ("Wardrobe", "#EFE6D9"), ("Practical", "#FFB060")]
        ),
        CatalogScheme(
            id: "sh-corp-5600",
            name: "Corporate 5600 Office",
            trade: .shoot,
            useWhen: "Office recap. 5600K through glass. Gray desk, navy wardrobe, white practical blinds.",
            lightNote: "Daylight through glass.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#E8EEF4"), ("Fill", "#8A9AAA"), ("Backdrop", "#C5C8CC"), ("Wardrobe", "#1F3358"), ("Practical", "#F7F7F4")]
        ),
        CatalogScheme(
            id: "sh-music-gel",
            name: "Music Promo Gel",
            trade: .shoot,
            useWhen: "Music promo. Magenta practical, cyan fill, black wardrobe. Mixed on purpose.",
            lightNote: "Mixed gel: warm vs cool.",
            shootLight: .mixed,
            pairs: [("Key", "#E8A0C8"), ("Fill", "#4AA8C8"), ("Backdrop", "#12081C"), ("Wardrobe", "#111111"), ("Practical", "#E827CB")]
        ),
        CatalogScheme(
            id: "sh-bridal-shade",
            name: "Bridal Open Shade",
            trade: .shoot,
            useWhen: "Bridal in shade. Ivory wardrobe, cool key, garden backdrop. No tungsten on the dress.",
            lightNote: "Open shade only.",
            shootLight: .openShade,
            pairs: [("Key", "#D4DEE6"), ("Fill", "#E8DCC8"), ("Backdrop", "#6E6B4F"), ("Wardrobe", "#F4EFE6"), ("Practical", "#F8F4EC")]
        ),
        CatalogScheme(
            id: "sh-workshop-tungsten",
            name: "Workshop Tungsten",
            trade: .shoot,
            useWhen: "Workshop interview. 3200K practicals, timber backdrop, denim wardrobe.",
            lightNote: "Tungsten shop lamps.",
            shootLight: .kelvin3200,
            pairs: [("Key", "#E0B884"), ("Fill", "#6E4B32"), ("Backdrop", "#5C4033"), ("Wardrobe", "#3A4A6A"), ("Practical", "#FFB060")]
        ),
        CatalogScheme(
            id: "sh-car-day",
            name: "Car Showroom Day",
            trade: .shoot,
            useWhen: "Showroom. 5600K, white key, graphite fill, no warm practicals on paint.",
            lightNote: "Daylight, even.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#F0F2F4"), ("Fill", "#5A6570"), ("Backdrop", "#E6E2DC"), ("Wardrobe", "#1F1F1F"), ("Practical", "#FFFFFF")]
        ),
        CatalogScheme(
            id: "sh-kids-pastel",
            name: "Kids Set Pastel 5600",
            trade: .shoot,
            useWhen: "Kids set. 5600K. Pastel key, coral wardrobe, no mixed household lamps.",
            lightNote: "Daylight, no mixed lamps.",
            shootLight: .kelvin5600,
            pairs: [("Key", "#F4E6D8"), ("Fill", "#B8D4C8"), ("Backdrop", "#F7F1E6"), ("Wardrobe", "#D989A0"), ("Practical", "#FFF6E8")]
        ),
        CatalogScheme(
            id: "sh-thriller-green",
            name: "Thriller Green Practical",
            trade: .shoot,
            useWhen: "Thriller night. Green practical, cool fill, black wardrobe. Mixed on purpose.",
            lightNote: "Mixed: green practical vs cool fill.",
            shootLight: .mixed,
            pairs: [("Key", "#6A8F71"), ("Fill", "#3A4A6A"), ("Backdrop", "#121820"), ("Wardrobe", "#1A1A1A"), ("Practical", "#3D8B3D")]
        ),
        CatalogScheme(
            id: "sh-beach-fill",
            name: "Beach Fill Shade",
            trade: .shoot,
            useWhen: "Beach, subject in shade. Cool key, sand backdrop, warm wardrobe so skin does not go gray.",
            lightNote: "Open shade on a bright beach.",
            shootLight: .openShade,
            pairs: [("Key", "#C5D4E0"), ("Fill", "#E6D5B8"), ("Backdrop", "#D7C4A3"), ("Wardrobe", "#C45C3A"), ("Practical", "#F8F4EC")]
        )
    ]
}
