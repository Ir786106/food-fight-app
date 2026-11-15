function isActiveProfile(profile, uid) {
  return !!profile && profile.isBlocked !== true &&
    (profile.role !== "super_admin" || uid == null ||
      [profile.id, profile.uid].every((id) => id == null || id === "" || id === uid)) &&
    !["blocked", "suspended", "deactivated", "inactive"].includes(profile.status) &&
    (profile.isActive == null || [true, 1, "1", "true"].includes(profile.isActive));
}

module.exports = { isActiveProfile };
