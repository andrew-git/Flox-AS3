package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.createUID;
    
    import starling.unit.UnitTest;
    
    public class AccessTest extends UnitTest
    {
        private static const KEY_1:String = "key1";
        private static const KEY_2:String = "key2";
        
        public override function setUp():void
        {
            Constants.initFlox();
            Player.logout();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testModificationWithAccessNone(onComplete:Function):void
        {
            makeModificationTest(Access.NONE, onComplete);
        }
        
        public function testModificationWithAccessRead(onComplete:Function):void
        {
            makeModificationTest(Access.READ, onComplete);
        }
        
        public function testModificationWithAccessReadWrite(onComplete:Function):void
        {
            makeModificationTest(Access.READ_WRITE, onComplete);
        }
        
        public function makeModificationTest(access:String, onComplete:Function):void
        {
            var entity:CustomEntity = null;
            Player.loginWithKey(KEY_1, onLoginPlayer1Complete, onError);
            
            function onLoginPlayer1Complete(player:Player):void
            {
                assertEqual(AuthenticationType.KEY, player.authType);
                
                entity = new CustomEntity("Gandalf", int(Math.random() * 1000));
                entity.publicAccess = access;
                entity.save(onEntitySaved, onError);
            }
            
            function onEntitySaved(entity:CustomEntity):void
            {
                Player.loginWithKey(KEY_2, onLoginPlayer2Complete, onError);
            }
            
            function onLoginPlayer2Complete(player:Player):void
            {
                Entity.load(CustomEntity, entity.id, onEntityLoadComplete, onEntityLoadError); 
            }
            
            function onEntityLoadComplete(entity:CustomEntity):void
            {
                if (access == Access.NONE)
                {
                    fail("Could load entity that was not publicly accessible");
                    onComplete();
                }
                else if (access == Access.READ || access == Access.READ_WRITE)
                {
                    entity.name = "Saruman";
                    entity.save(onEntitySaveComplete, onEntitySaveError);
                }
            }
            
            function onEntitySaveComplete():void
            {
                if (access == Access.READ)
                    fail("Could save READ-only entity");

                onComplete();
            }
            
            function onEntitySaveError(error:String):void
            {
                if (access == Access.READ_WRITE)
                    fail("Could not modify READ_WRITE entity: " + error);
                
                onComplete();
            }
            
            function onEntityLoadError(error:String, httpStatus:int, cachedEntity:Entity):void
            {
                if (access == Access.NONE)
                    assertFalse(HttpStatus.isTransientError(httpStatus));
                else
                    fail("Could not load entity with '" + access + "' access: " + error);
                
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
            {
                fail("Entity handling failed: " + error);
                onComplete();
            }
        }
        
        public function testDestructionWithAccessNone(onComplete:Function):void
        {
            makeDestructionTest(Access.NONE, onComplete);
        }
        
        public function testDestructionWithAccessRead(onComplete:Function):void
        {
            makeDestructionTest(Access.READ, onComplete);
        }
        
        public function testDestructionWithAccessReadWrite(onComplete:Function):void
        {
            makeDestructionTest(Access.READ_WRITE, onComplete);
        }
        
        public function makeDestructionTest(access:String, onComplete:Function):void
        {
            Player.logout(); // login new guest
            
            var entity:CustomEntity = new CustomEntity("Sauron", int(Math.random() * 1000));
            entity.publicAccess = access;
            entity.save(onEntitySaved, onError);
            
            function onEntitySaved(entity:CustomEntity):void
            {
                Player.logout(); // login new guest
                Entity.destroy(CustomEntity, entity.id, onDestroyComplete, onDestroyError);
            }
            
            function onDestroyComplete():void
            {
                if (access != Access.READ_WRITE)
                    fail("could destroy entity even though access rights were " + access);
                
                onComplete();
            }
            
            function onDestroyError(error:String, httpStatus:int):void
            {
                if (access == Access.READ_WRITE)
                    fail("could not destroy entity even though access rights were " + access);
                
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
            {
                fail("Entity handling failed: " + error);
                onComplete();
            }
        }
        
        public function testChangeOwnership(onComplete:Function):void
        {
            var name:String = createUID();
            var entity:Entity = new CustomEntity(name, 32);
            entity.publicAccess = Access.NONE;
            entity.save(onSaveComplete, onError);
            
            function onSaveComplete():void
            {
                entity.ownerId = createUID();
                entity.save(onSave2Complete, onError);
            }
            
            function onSave2Complete():void
            {
                var query:Query = new Query(CustomEntity, "name == ?", name);
                query.find(onQueryComplete, onError);
            }
            
            function onQueryComplete(entities:Array):void
            {
                assertEqual(0, entities.length, "received result from query, but shouldn't");
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail(error);
                onComplete();
            }
        }
    }
}

import com.gamua.flox.Player;

class CustomPlayer extends Player
{
    private var mLastName:String;
    
    public function CustomPlayer(lastName:String="unknown")
    {
        mLastName = lastName;
    }
    
    public function get lastName():String { return mLastName; }
    public function set lastName(value:String):void { mLastName = value; }
}