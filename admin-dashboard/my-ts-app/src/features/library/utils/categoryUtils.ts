// أداة مساعدة لتعيين لون ثابت لكل فئة بناءً على اسمها.
// الهدف هو إعطاء كل فئة مظهرًا متسقًا من دون الحاجة لتحديد ألوان يدويًا لكل فئة.

export const getCategoryColor = (category: string) => {
  // دالة تجزئة بسيطة لتحويل النص إلى رقم.
  const hashString = (str: string) => {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // تحويل إلى 32-bit integer
    }
    return Math.abs(hash);
  };

  // قائمة أنماط الألوان المستخدمة للفئات.
  // تتضمن خلفية ونص وحدود لتظهر بشكل جيد في البطاقة.
  const colors = [
    'bg-blue-100 text-blue-700 border-blue-200',
    'bg-green-100 text-green-700 border-green-200',
    'bg-emerald-100 text-emerald-700 border-emerald-200',
    'bg-teal-100 text-teal-700 border-teal-200',
    'bg-cyan-100 text-cyan-700 border-cyan-200',
    'bg-sky-100 text-sky-700 border-sky-200',
    'bg-indigo-100 text-indigo-700 border-indigo-200',
    'bg-purple-100 text-purple-700 border-purple-200',
    'bg-violet-100 text-violet-700 border-violet-200',
    'bg-fuchsia-100 text-fuchsia-700 border-fuchsia-200',
    'bg-pink-100 text-pink-700 border-pink-200',
    'bg-rose-100 text-rose-700 border-rose-200',
    'bg-red-100 text-red-700 border-red-200',
    'bg-orange-100 text-orange-700 border-orange-200',
    'bg-amber-100 text-amber-700 border-amber-200',
    'bg-yellow-100 text-yellow-700 border-yellow-200',
    'bg-lime-100 text-lime-700 border-lime-200',
    'bg-slate-100 text-slate-700 border-slate-200',
    'bg-gray-100 text-gray-700 border-gray-200',
    'bg-zinc-100 text-zinc-700 border-zinc-200',
    'bg-neutral-100 text-neutral-700 border-neutral-200',
    'bg-stone-100 text-stone-700 border-stone-200'
  ];

  // نستخدم التجزئة لاختيار لون ثابت من القائمة بناءً على اسم الفئة.
  const hash = hashString(category);
  const colorIndex = hash % colors.length;

  return colors[colorIndex];
};
