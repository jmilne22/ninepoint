"""Physical and export geometry for generated props. Coordinates stay in pixels."""
from dataclasses import dataclass


@dataclass(frozen=True)
class PropSpec:
    size: tuple[int, int]
    footprint: tuple[int, int, int, int] | None = None
    holds: tuple[float, ...] = ()

    def decorate(self, entry):
        if self.footprint:
            _,by,_,bh=self.footprint
            entry['base']=entry['position'][1]+by+bh
        if self.holds:
            entry['animation']={'frames':len(self.holds),'holds':list(self.holds)}


SPECS={
    'washer_bank':PropSpec((80,26),(0,10,80,16),(.8,1.1,.9,1.2)),
    'folding_counter':PropSpec((64,32),(0,16,64,16)),
    'bar_counter':PropSpec((64,32),(0,16,64,16)),
    'playing_table':PropSpec((48,32),(0,0,48,32)),
    'tournament_table':PropSpec((48,32),(0,0,48,32)),
    'school_table':PropSpec((48,32),(0,0,48,32)),
    'long_bench':PropSpec((48,24),(0,8,48,16)),
    'study_desk':PropSpec((32,32),(0,0,32,32)),
    'bed':PropSpec((32,48),(0,0,32,48)),
    'reception':PropSpec((64,40),(0,16,64,24)),
    'student_desk':PropSpec((48,24),(0,0,48,16)),
    'tea_station':PropSpec((48,32),(0,16,48,16)),
    'laundry_basket':PropSpec((24,24),(0,8,24,16)),
    'dry_corner':PropSpec((80,48),(8,32,48,16)),
    'port_cargo':PropSpec((64,32),(0,16,64,16)),
    'review_board':PropSpec((48,40),(0,24,48,16)),
    'tram_stop':PropSpec((48,48),(16,32,32,16)),
    'coat_rack':PropSpec((48,32)), 'tall_window':PropSpec((32,48)),
    'book_shelf':PropSpec((48,32)), 'kettle_sign':PropSpec((48,40)),
    'attic_roof':PropSpec((192,48)), 'port_arch':PropSpec((112,88)),
    'school_glass':PropSpec((96,48)), 'school_directions':PropSpec((48,24)),
    'shopfront_wassalon':PropSpec((48,32)), 'shopfront_ketel':PropSpec((48,32)),
    'shopfront_stationer':PropSpec((48,32)), 'demonstration':PropSpec((64,48)),
    'snack_stool':PropSpec((24,24)), 'facade_detail':PropSpec((128,64)),
}
for person in ('noor','ivo','lea','emil','sora'):
    SPECS['novice_'+person]=PropSpec((48,48),(0,0,48,32))
for number in range(1,13):SPECS['board_number_'+str(number)]=PropSpec((16,9))
for facade in ('home','bar','laundry'):
    SPECS['sela_'+facade]=PropSpec((128,128))
SPECS.update(sela_pergola=PropSpec((128,48)),
             sela_kiosk=PropSpec((48,48),(0,32,48,16),(2.8,.25,.5)),
             sela_garden=PropSpec((48,32),(0,16,48,16)),
             sela_tree=PropSpec((64,56),(24,40,16,16),(2.4,.5,1.3)))


def validate_asset(name,image):
    spec=SPECS[name]
    w,h=spec.size
    assert (image.w,image.h)==(w*max(1,len(spec.holds)),h), (name,image.w,image.h,spec)


def footprints():
    return {name:(*spec.size,*spec.footprint) for name,spec in SPECS.items() if spec.footprint}
