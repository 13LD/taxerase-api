export function currentReturnPath() {
  if (typeof window === "undefined") return "/";

  return `${window.location.pathname}${window.location.search}`;
}

export function authPathWithReturnTo(path) {
  if (typeof window === "undefined") return path;

  const url = new URL(path || "/sign_in", window.location.origin);
  url.searchParams.set("return_to", currentReturnPath());

  return `${url.pathname}${url.search}`;
}
