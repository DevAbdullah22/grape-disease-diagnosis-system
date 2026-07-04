// مكون يدير عرض وإدخال مصادر المحتوى وقوائم الروابط مع صلاحية التحقق من الأمان.
import { AlertTriangle, Link, Plus, X } from 'lucide-react';

import { Button } from '../../../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Input } from '../../../components/ui/input';

interface SourceListProps {
  sources: string[];
  errors: { [key: string]: string };
  onAddSource: () => void;
  onUpdateSource: (index: number, value: string) => void;
  onRemoveSource: (index: number) => void;
  isValidSecureSourceUrl: (value: string) => boolean;
  getSourceHostname: (value: string) => string;
  isTrustedSourceDomain: (hostname: string) => boolean;
}

export function SourceList({
  sources,
  errors,
  onAddSource,
  onUpdateSource,
  onRemoveSource,
  isValidSecureSourceUrl,
  getSourceHostname,
  isTrustedSourceDomain
}: SourceListProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Link className="h-5 w-5 text-green-600" />
          المصادر والروابط <span className="text-gray-500 text-xs">(اختياري)</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* تحذير المستخدم حول مسؤولية إضافة مصادر موثوقة */}
        <div className="rounded-lg border border-amber-300 bg-amber-50 p-3 sm:p-4">
          <div className="flex items-start gap-2 text-amber-900 text-right">
            <AlertTriangle className="h-5 w-5 mt-0.5 shrink-0" />
            <p className="text-sm sm:text-base font-semibold">
               تنبيه: يرجى إضافة مصادر موثوقة فقط. يتحمل المسؤول مسؤولية صحة الروابط المضافة.
            </p>
          </div>
        </div>

        {/* قائمة الحقول الديناميكية لكل مصدر */}
        {sources.map((source, index) => {
          const trimmedSource = source.trim();
          const sourceInvalid = !!trimmedSource && !isValidSecureSourceUrl(trimmedSource);

          return (
            <div key={index} className="space-y-1">
              <div className="flex gap-2">
                <Input
                  placeholder="رابط مصدر أو فيديو تطبيقي"
                  value={source}
                  onChange={(e) => {
                    onUpdateSource(index, e.target.value);
                  }}
                  className={`text-right flex-1 ${sourceInvalid ? 'border-red-500 focus-visible:ring-red-500' : ''}`}
                />
                {/* إمكانية حذف مصدر واحد من القائمة في حال وجود أكثر من مصدر */}
                {sources.length > 1 && (
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={() => onRemoveSource(index)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                )}
              </div>
              {sourceInvalid && (
                <p className="text-red-600 text-xs">
                  الرابط غير آمن أو غير صالح. يسمح فقط بروابط https://
                </p>
              )}
            </div>
          );
        })}

        {/* زر لإضافة حقل مصدر جديد */}
        <Button
          variant="outline"
          onClick={onAddSource}
          className="w-full flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          إضافة مصدر آخر
        </Button>

        {/* عرض الروابط المضافة مع تقييم مصداقيتها */}
        {sources.some(source => source.trim()) && (
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <p className="text-sm text-gray-600 mb-2">الروابط المضافة:</p>
            <ul className="space-y-1">
              {sources
                .map(source => source.trim())
                .filter(Boolean)
                .map((source, index) => {
                  const hostname = getSourceHostname(source);
                  const trusted = isTrustedSourceDomain(hostname);

                  return (
                    <li key={index} className="text-sm text-blue-600 break-all">
                      <div className="flex items-start justify-between gap-3">
                        <span>• {source}</span>
                        <span className={`text-xs px-2 py-0.5 rounded-full border whitespace-nowrap ${trusted ? 'bg-green-50 text-green-700 border-green-300' : 'bg-amber-50 text-amber-700 border-amber-300'}`}>
                          {trusted ? 'موثوق' : 'غير موثوق'}
                        </span>
                      </div>
                      {hostname && (
                        <p className="text-[11px] text-gray-500 mt-0.5">
                          النطاق: {hostname}
                        </p>
                      )}
                    </li>
                  );
                })}
            </ul>
          </div>
        )}

        {/* عرض رسالة خطأ مصادر إن وجدت */}
        {errors.sources && (
          <p className="text-red-600 text-sm">{errors.sources}</p>
        )}
      </CardContent>
    </Card>
  );
}
