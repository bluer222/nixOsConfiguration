"""Program native lighting once; no animation loop or background process."""

import effects
import keyboard
import profiles


def apply(profile):
    profile = profiles.validate(profile)
    reports, assigned = effects.onboard_programs(profile)
    return keyboard.apply(effects.base_frame(profile), profile["brightness"], profile["enabled"],
                          key_reactive=effects.reactive_configs(profile), key_effects=assigned, effect_reports=reports)
