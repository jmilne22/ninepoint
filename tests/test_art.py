"""Contracts the art facelift must preserve, independent of Godot's import cache."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'tools'))
from png import Img
from pixel_art import polygon, ellipse, mask, clipped, remap, seed
from palette import rgb
from preview import load
from art_specs import SPECS, validate_asset
import gen_tiles
import gen_characters
import gen_venue_props
import gen_venue_scenes


class ArtContracts(unittest.TestCase):
    def test_portraits_are_original_pixels_and_exports(self):
        baseline=json.loads((ROOT/'tests/art_portraits.sha256.json').read_text())
        with tempfile.TemporaryDirectory() as temp:
            gen_characters.build(Path(temp)/'sprites',Path(temp)/'portraits',sprites=False)
            self.assertFalse((Path(temp)/'sprites').exists())
            for name,digest in baseline.items():
                actual=ROOT/name;rebuilt=Path(temp)/'portraits'/actual.name
                self.assertEqual(hashlib.sha256(actual.read_bytes()).hexdigest(),digest,name)
                self.assertEqual(rebuilt.read_bytes(),actual.read_bytes(),name)

    def test_navigation_is_unchanged(self):
        reference=json.loads((ROOT/'tests/art_navigation.sha256.json').read_text())
        fields=('size','solid','spawns','warps','signs','npcs')
        for name,digest in reference.items():
            data=json.loads((ROOT/('data/maps/'+name+'.json')).read_text())
            actual=hashlib.sha256(json.dumps({k:data[k] for k in fields},sort_keys=True).encode()).hexdigest()
            self.assertEqual(actual,digest,name)
            if name in ('academy_class','academy_dorm'):
                self.assertNotIn(',', ''.join(data['ground']), name+' must retain wooden flooring')

    def test_masked_material_stays_inside_shape(self):
        silhouette=Img(8,8);polygon(silhouette,[(1,1),(7,1),(7,3),(3,3),(3,7),(1,7)],'wood1')
        paint=Img(8,8,rgb('gold2'));target=Img(8,8)
        clipped(target,paint,mask(silhouette))
        self.assertEqual(target.get(2,5),rgb('gold2'))
        self.assertEqual(target.get(5,5),(0,0,0,0))
        self.assertEqual(target.get(0,0),(0,0,0,0))
        self.assertEqual(target.get(6,2),rgb('gold2'))

    def test_ellipse_and_remap_preserve_transparency(self):
        im=Img(8,8);ellipse(im,1,2,6,4,'blue0')
        recoloured=remap(im,{'blue0':'blue1'})
        self.assertEqual(recoloured.get(4,4),rgb('blue1'))
        self.assertEqual(recoloured.get(0,0),(0,0,0,0))
        self.assertEqual(sum(im.buf[3::4]),sum(recoloured.buf[3::4]))

    def test_atlas_order_does_not_change_art(self):
        original=gen_tiles.TILES[:]
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            try:
                gen_tiles.build(root/'a')
                gen_tiles.TILES[:]=list(reversed(original))
                gen_tiles.build(root/'b')
            finally:gen_tiles.TILES[:]=original
            images=[load(root/d/'town_tileset.png') for d in ('a','b')]
            manifests=[json.loads((root/d/'tileset_manifest.json').read_text()) for d in ('a','b')]
            for name in manifests[0]['tiles']:
                cells=[]
                for atlas,man in zip(images,manifests):
                    x,y=man['tiles'][name];cells.append(atlas.sub(x*16,y*16,16,16).buf)
                self.assertEqual(cells[0],cells[1],name)
        self.assertNotEqual(seed('table','grain'),seed('table','wear'))

    def test_prop_geometry_and_exports(self):
        for name,fn in {**gen_venue_props.ASSETS,**gen_venue_scenes.ASSETS}.items():
            spec=SPECS[name];actual=load(ROOT/('art/props/'+name+'.png'))
            validate_asset(name,actual)
            if spec.footprint:
                x,y,w,h=spec.footprint
                self.assertGreater(w*h,0)
                self.assertLessEqual(x+w,spec.size[0]);self.assertLessEqual(y+h,spec.size[1])
            if not spec.holds:self.assertEqual(actual.buf,fn().buf,name)

    def test_washer_shell_is_still_while_cloth_moves(self):
        frames=[gen_venue_props.washer_bank(i) for i in range(4)]
        for a,b in zip(frames,frames[1:]):
            changed=0
            for y in range(a.h):
                for x in range(a.w):
                    if a.get(x,y)!=b.get(x,y):
                        changed+=1
                        self.assertTrue(5<=x%20<15 and 10<=y<20,(x,y))
            self.assertGreater(changed,0)

    def test_presentation_has_no_transparent_cuts_or_new_text_noise(self):
        for name in ('title','opening'):
            im=load(ROOT/('art/title/'+name+'.png'))
            self.assertEqual((im.w,im.h),(384,216))
            self.assertTrue(all(a==255 for a in im.buf[3::4]),name)
        import gen_ui
        panel=gen_ui.panel()
        self.assertEqual({panel.get(x,y) for x in range(6,18) for y in range(6,18)},{rgb('paper0')})
        for name,size in [('bowl',(44,30)),('hands',(78,104)),('board_surface',(32,32))]:
            im=load(ROOT/('art/ui/'+name+'.png'));self.assertEqual((im.w,im.h),size)

    def test_character_sheet_contracts(self):
        from characters import CHARACTERS
        from art_people import sprite_sheet, action_sheet
        for character in CHARACTERS:
            name=character['id']
            for suffix,draw,size in [('',sprite_sheet,(48,96)),('_actions',action_sheet,(32,480))]:
                exported=load(ROOT/('art/sprites/'+name+suffix+'.png'))
                self.assertEqual((exported.w,exported.h),size,name)
                self.assertEqual(exported.buf,draw(character).buf,name+suffix)
            walk=sprite_sheet(character)
            self.assertNotEqual(walk.sub(16,0,16,24).buf,walk.sub(32,0,16,24).buf,name)
            self.assertNotEqual(walk.sub(0,0,16,24).buf,walk.sub(0,72,16,24).buf,name)
            self.assertTrue(any(walk.get(x,23)[3] for x in range(16)),name)

    def test_selective_build_is_deterministic_and_isolated(self):
        with tempfile.TemporaryDirectory() as temp:
            target=Path(temp)
            cmd=[sys.executable,str(ROOT/'tools/build_assets.py'),'--groups','environments','--output',str(target)]
            subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL,cwd=ROOT)
            first={str(p.relative_to(target)):p.read_bytes() for p in target.rglob('*') if p.is_file()}
            subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL,cwd=ROOT)
            second={str(p.relative_to(target)):p.read_bytes() for p in target.rglob('*') if p.is_file()}
            self.assertEqual(first,second)
            self.assertTrue((target/'art/tiles/town_tileset.tres').exists())
            self.assertEqual(len(list((target/'data/maps').glob('*.json'))),12)
            for path in ['audio','art/portraits','art/sprites','art/ui']:
                self.assertFalse((target/path).exists(),path)


if __name__=='__main__':unittest.main()
