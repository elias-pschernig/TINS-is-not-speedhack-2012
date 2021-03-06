/*
Copyright 2012 Pavel Sountsov

This file is part of TINSEngine.

TINSEngine is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TINSEngine is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with TINSEngine.  If not, see <http://www.gnu.org/licenses/>.
*/
module engine.PriorityEvent;

import tango.core.Array;
import tango.io.Stdout;

final class CPriorityEvent(TArgs...)
{
	alias void delegate(TArgs) TDelegate;
	
	struct SDelegateHolder
	{
		TDelegate Delegate;
		int Priority;
		
		static bool Less(SDelegateHolder a, SDelegateHolder b)
		{
			return a.Priority < b.Priority || (a.Priority == b.Priority
			       && (a.Delegate.ptr < b.Delegate.ptr || (a.Delegate.ptr == b.Delegate.ptr
			       && a.Delegate.funcptr < b.Delegate.funcptr)));
		}
	}
	
	void Register(TDelegate dg, int priority = 0)
	{
		auto holder = SDelegateHolder(dg, priority);
		auto where = DelegateHolders.lbound(holder, &SDelegateHolder.Less);
		DelegateHolders.length = DelegateHolders.length + 1;
		
		for(size_t ii = DelegateHolders.length - 1; ii > where; ii--)
			DelegateHolders[ii] = DelegateHolders[ii - 1];
		
		DelegateHolders[where] = holder;
	}
	
	void UnRegister(TDelegate dg)
	{
		auto new_len = DelegateHolders.removeIf((SDelegateHolder a) => dg is a.Delegate);
		DelegateHolders.length = new_len;
	}
	
	void Trigger(TArgs args)
	{
		foreach(holder; DelegateHolders)
			holder.Delegate(TArgs);
	}
	@property
	size_t length()
	{
		return DelegateHolders.length;
	}
protected:
	SDelegateHolder[] DelegateHolders;
} 

version(UnitTest)
{
	import tango.text.convert.Format;
	unittest
	{
		auto event = new CPriorityEvent!();
		int[] call_stack;

		void delegate() dg = {call_stack ~= 2;};
		event.Register({call_stack ~= 3;}, 3);
		event.Register({call_stack ~= 1;}, 1);
		event.Register(dg, 2);
		event.Trigger();
		assert(call_stack == [1, 2, 3], Format("{}", call_stack));
		call_stack.length = 0;
		
		event.UnRegister(dg);
		event.Trigger();
		assert(call_stack == [1, 3], Format("{}", call_stack));
		
		call_stack.length = 0;
		
		event = new CPriorityEvent!();
		
		class A
		{
			void test1()
			{
				call_stack ~= 1;
			}
			
			void test2()
			{
				call_stack ~= 2;
			}
		}
		
		class B
		{
			void test3()
			{
				call_stack ~= 3;
			}
		}
		
		auto a = new A;
		auto b = new B;
		
		event.Register(&a.test1, 2);
		event.Register(&a.test2, 1);
		event.Register(&b.test3, 3);
		
		event.Trigger();
		
		assert(call_stack == [2, 1, 3], Format("{}", call_stack));
	}
}
