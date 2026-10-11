class_name BallPhysics
extends Resource






@export var radius: = 0.26

@export var gravity: = 11.0

@export var floor_bounce: = 0.5

@export var floor_friction: = 0.75

@export var roll_drag: = 4.0

@export var net_height: = 2.2










@export var spike_lock_free: = 15.0
@export var spike_lock_gain: = 0.09
@export var spike_lock_max: = 0.7

@export var quick_arrive_h: = 3.5



@export var set_arrive_h: = 3.0









@export var tape_band: = 0.1
@export var tape_pop_base: = 1.3
@export var tape_pop_gain: = 0.12
@export var tape_pop_min: = 1.7
@export var tape_pop_max: = 3.4
@export var tape_drift: = 0.35
@export var tape_side_damp: = 0.15

@export var net_half_width: = 4.7
@export var antenna_half_width: = 4.5





@export var tool_keep: = 0.6

@export var tool_bleed: = 0.014

@export var tool_keep_min: = 0.28

@export var tool_smear: = 4.0

@export var tool_max_speed: = 8.0

@export var tool_lift: = 2.2

@export var tool_lift_gain: = 0.06

@export var trail_min_speed: = 5.0








@export var spike_min_speed: = 4.0







@export var spike_speed_slow: = 8.0
@export var spike_speed_fast: = 30.0
@export var spike_min_flight: = 0.28
@export var spike_min_flight_slow: = 0.85

@export var dump_min_speed: = 7.0

@export var pass_max_speed: = 12.0

@export var quick_set_max_speed: = 24.0








@export var set_near_dist: = 1.4
@export var set_far_dist: = 5.0
@export var set_near_full_time: = 2.5












@export var attack_clear_soft: = 0.8
@export var attack_clear_tight: = 0.04
@export var pass_clear_margin: = 0.35

@export var curve_strength: = 12.0
@export var curve_ref_speed: = 13.0







@export var curve_decay_time: = 0.5









@export var float_serve_time_slow: = 1.6
@export var float_serve_time_fast: = 1.3
@export var float_time_factor: = 1.25

@export var drive_time_factor: = 0.85



@export var outline_home: = Color(0.35, 1.0, 0.55)

@export var outline_away: = Color(1.0, 0.25, 0.72)




@export var trail_fast: = Color(0.34, 0.8, 1.0)
@export var trail_fast_speed: = 13.0








@export var magnet_lean_max: = 0.12
