"""Reuse the numerical STL cleanup without modifying any V2 artifacts."""
from pathlib import Path
import importlib.util
import json

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('screw_finish', ROOT.parent/'prototype_v2/experimental_screws/finish_stls.py')
finish = importlib.util.module_from_spec(spec)
spec.loader.exec_module(finish)
finish.ROOT = ROOT
if __name__ == '__main__':
    print(json.dumps([finish.finish(n) for n in ['housing','fit_coupon','test_spacers']],indent=2))
