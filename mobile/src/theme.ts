export const colors = {
  green: "#16834b", greenDark: "#11683b", greenSoft: "#edf7f0",
  ink: "#17251e", muted: "#78857d", line: "#e8eee9",
  background: "#fbfcfb", white: "#ffffff", danger: "#d84d5b",
};
export const categories = ["Tümü","Elektronik","Telefon","Bilgisayar","Ev ve Yaşam","Moda","Giyim","Araç","Yedek Parça","Spor","Hobi","Anne ve Bebek","Diğer"];
export const formatPrice = (value: number) => new Intl.NumberFormat("tr-TR",{style:"currency",currency:"TRY",maximumFractionDigits:0}).format(value);
