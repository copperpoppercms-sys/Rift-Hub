# Restore the Rift intro

The intro video and Welcome to Rift sequence are temporarily disabled at the entrypoint. The main hub opens immediately. Home-video playback in the hub is separate.

To restore both stages, set `INTRO_ENABLED = true` in `main.lua`. The existing `src/ui/Intro.lua`, video frame pack, audio, welcome artwork, skip button and welcome-audio timing remain in place.

The complete pre-disable repository is preserved at commit `d69f144e0a0bf38778fd5956894af300645f6820` and branch `archive/intro-with-welcome-2026-10-18`. No intro modules or media were deleted or rewritten.

An additional downloadable ZIP was saved as `RiftHub_Intro_Backup_2026-10-18.zip` in the shared workspace.
